(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

open Lwt
open Printf
open Json_type

(* TODO: take care of delete messages *)

let min_reconnect_interval = 5.  (* seconds *)

let url_of_type = function
  | `Firehose -> "http://stream.twitter.com/1/statuses/firehose.json"
  | `Sample   -> "http://stream.twitter.com/1/statuses/sample.json"
  | `Custom url -> url

let do_http_fetch (username, password) url fd =
  let channel_writer data = Unix.write fd data 0 (String.length data)
  and error_buffer = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  try
    let connection = Curl.init () in
    Curl.set_errorbuffer connection error_buffer;
    Curl.set_writefunction connection channel_writer;
    Curl.set_url connection (url_of_type url);
    Curl.setopt connection (Curl.CURLOPT_HTTPAUTH [Curl.CURLAUTH_ANY]);
    Curl.set_userpwd connection (sprintf "%s:%s" username password);
    Curl.perform connection;
    Curl.cleanup connection
  with
    | Curl.CurlException (reason, code, str) ->
        fprintf stderr "Error: %s\n" !error_buffer
    | Failure s ->
        fprintf stderr "Caught exception: %s\n" s;
        Curl.global_cleanup ()

let rec fork_http_fetcher' ?(connect_time = 0.) auth url out_fd =
  match Unix.fork () with
    | 0 -> do_http_fetch auth url out_fd; return ()
    | child_pid ->
        (* Respawn on death. Let's limit reconnects to .*)
        Lwt_unix.waitpid [] child_pid >> 
        let time_left =
          min_reconnect_interval -. (Unix.time () -. connect_time) in
        begin  (* ensure that we aren't too aggressive with reconnects. *)
          if time_left > 0.
          then Lwt_unix.sleep time_left
          else return ()
        end >>
        fork_http_fetcher' ~connect_time:(Unix.time ()) auth url out_fd

let fork_http_fetcher auth url =
  let (in_fd, out_fd) = Unix.pipe () in
  let monitor_t = fork_http_fetcher' auth url out_fd in
  monitor_t, Lwt_io.of_unix_fd Lwt_io.input in_fd

let rec push_to_stream push_stream chan =
  try_bind (fun () -> Lwt_io.read_line chan) 
    begin fun line ->
      begin match Twitterstream_status.of_json_string line with
        | Some _ as s -> push_stream s
        | None -> ()
      end;
      push_to_stream push_stream chan
    end 
    (fun ex (* only on EOF? *) -> push_stream None; return ())

let of_channel channel =
  let (stream, push_stream) = Lwt_stream.create () in
  push_to_stream push_stream channel, stream

let of_http_stream userpass url_type =
  let monitor_t, channel = fork_http_fetcher userpass url_type in
  let t, stream = of_channel channel in
  join [monitor_t; t], stream
