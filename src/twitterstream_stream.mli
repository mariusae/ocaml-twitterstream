
exception Stream_http_error of int
exception Stream_tcp_error

type reconnect_policy = {
  max_tries         : int;
  max_tries_per_sec : int;
}

val stream_of_channel : 
  Lwt_io.input Lwt_io.channel -> 
  Twitterstream_message.t Lwt_stream.t

val open_stream :
  ?reconnect_policy:reconnect_policy ->
  string * string -> 
  [ `Custom of string | `Firehose | `Sample ] -> 
  unit Lwt.t * Twitterstream_message.t Lwt_stream.t
