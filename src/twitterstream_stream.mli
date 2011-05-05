(**
 Twitter streaming API client using lwt.
 @author marius a. eriksen
 *)

(** HTTP error with the given code. *)
exception Stream_http_error of int

(** A TCP error *)
exception Stream_tcp_error

(** Describe a reconnect policy.  *)
type reconnect_policy = {
  max_tries         : int;
  max_tries_per_sec : int;
}

(**
 Convert a channel of bytes (eg. raw stream output) to a
 {!Lwt_stream.t} of stautses
 *)
val stream_of_channel : 
  Lwt_io.input Lwt_io.channel -> 
  Twitterstream_message.t Lwt_stream.t

(**
 Open a new stream
 @param reconnect_policy the reconnection policy
 @param auth a tuple of
 @param stream the stream to connect to.
 @return producer thread and a {!Lwt_stream.t} of statuses
 *)
val open_stream :
  ?reconnect_policy:reconnect_policy ->
  string * string -> 
  [ `Custom of string | `Firehose | `Sample ] -> 
  unit Lwt.t * Twitterstream_message.t Lwt_stream.t
