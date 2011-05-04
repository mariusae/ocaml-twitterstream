open Lwt
open Printf
open Json_type
open Cohttp

exception Stream_http_error of int
exception Stream_tcp_error

type reconnect_policy = {
  max_tries         : int;
  max_tries_per_sec : int;
}

module Throttler = Lwt_throttle.Make(
  (* a singleton throttler. *)
  struct
    type t = unit
    let equal () () = true
    let hash () = 0
  end)

let url_of_type = function
  | `Firehose -> "http://stream.twitter.com/1/statuses/firehose.json"
  | `Sample   -> "http://stream.twitter.com/1/statuses/sample.json"
  | `Custom url -> url

let stream_of_channel chan =
  let lines = Lwt_io.read_lines chan in
  let map_line line =
    return (Twitterstream_message.of_json_string line) in
  Lwt_stream.map_s map_line lines

let connect (user, pass) url_type =
  let (input, output) = Lwt_io.pipe () in
  let stream = stream_of_channel input in

  let t = begin
    let userpass_str = Base64.str_encode (user ^ ":" ^ pass) in
    let headers = [
      "Host", "stream.twitter.com";
      "Authorization", "Basic " ^ userpass_str
    ] in

    try_lwt
      Http_client.get_to_chan (url_of_type url_type) ~headers output >>
      return ()
    with
      | Http_client.Tcp_error (source, _) ->
          fail Stream_tcp_error
      | Http_client.Http_error (code, _, _) ->
          fail (Stream_http_error code)
    finally
      Lwt_io.close output
  end in

  t, stream

let reconnect policy auth url_type =
  let stream, push = Lwt_stream.create () in
  let throttler = Throttler.create
    ~rate:policy.max_tries_per_sec
    ~max:(policy.max_tries_per_sec * policy.max_tries)
    ~n:1 in
  let rec go state =
    try_lwt
      (* TODO: success resets the tries? *)
      let (t, stream) = connect auth url_type in
      join [Lwt_stream.iter (fun item -> push (Some item)) stream; t]
    with
      | exc ->
          if state.max_tries > 1 then
            Throttler.wait throttler () >>
            go { state with max_tries = state.max_tries - 1 }
          else
            (push None; fail exc)
  in go policy, stream

let open_stream
  ?(reconnect_policy = {max_tries = 1; max_tries_per_sec = 1})
  auth url_type = reconnect reconnect_policy auth url_type
