open Lwt
open Printf
open Json_type
open Cohttp

exception Stream_http_error of int
exception Stream_tcp_error

type reconnect_policy = {
  max_tries                  : int;
  initial_reconnect_interval : float;
}

let url_of_stream_type = function
  | `Firehose   -> "http://stream.twitter.com/1/statuses/firehose.json"
  | `Sample     -> "http://stream.twitter.com/1/statuses/sample.json"
  | `Custom url -> url

let stream_of_channel chan =
  let lines = Lwt_io.read_lines chan in
  let map_line line =
    return (Twitterstream_message.of_json_string line) in
  Lwt_stream.map_s map_line lines

let connect (user, pass) stream_type =
  let (input, output) = Lwt_io.pipe () in
  let stream = stream_of_channel input in

  let t = begin
    let userpass_str = Base64.str_encode (user ^ ":" ^ pass) in
    let headers = [
      "Host", "stream.twitter.com";
      "Authorization", "Basic " ^ userpass_str
    ] in
    let url = url_of_stream_type stream_type in

    try_lwt
      Http_client.get_to_chan url ~headers output >> return ()
    with
      | Http_client.Tcp_error (source, _) ->
          fail Stream_tcp_error
      | Http_client.Http_error (code, _, _) ->
          fail (Stream_http_error code)
    finally
      Lwt_io.close output
  end in

  t, stream

let reconnect max_tries initial_reconnect_interval auth stream_type =
  let stream, push = Lwt_stream.create () in
  let throttle = Twitterstream_throttle.make
    ~initial_reconnect_interval ~max_attempts:max_tries in
  let rec go throttle =
    try_lwt
      (* TODO: success resets the tries? *)
      let (t, stream) = connect auth stream_type in
      let iter_t = Lwt_stream.iter (fun item -> push (Some item)) stream in
      join [iter_t; t]
    with
      | exc ->
          lwt throttle' = Twitterstream_throttle.wait throttle in
          match throttle' with
            | Some throttle' -> go throttle'
            | None           -> (push None; fail exc)
  in go throttle, stream

let open_stream
  ?(max_tries = 1) ?(initial_reconnect_interval = 1.)
  auth stream_type =
    reconnect max_tries initial_reconnect_interval auth stream_type
