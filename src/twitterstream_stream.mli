(**
 Twitter streaming API client using [lwt].
 @author marius a. eriksen
 *)

(** HTTP error with the given code. *)
exception Stream_http_error of int

(** A TCP error *)
exception Stream_tcp_error

(**
 Convert a channel of bytes (eg. raw stream output) to a
 {!Lwt_stream.t} of stautses
 *)
val stream_of_channel : 
  Lwt_io.input Lwt_io.channel -> 
  Twitterstream_message.t Lwt_stream.t

(**
 Open a new stream
 @param max_tries maximum number of connection attempts
 @param initial_reconnect_interval initial wait time for reconnect in seconds
 @param auth a tuple of
 @param stream the stream to connect to.
 @return producer thread and a {!Lwt_stream.t} of statuses
 *)
val open_stream :
  ?max_tries:int ->
  ?initial_reconnect_interval:float ->
  string * string -> 
  [ `Custom of string | `Firehose | `Sample ] -> 
  unit Lwt.t * Twitterstream_message.t Lwt_stream.t
