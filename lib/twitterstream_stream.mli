
val of_channel : 
  Lwt_io.input Lwt_io.channel -> 
  unit Lwt.t * Twitterstream_status.t Lwt_stream.t

val of_http_stream : 
  string * string -> 
  [< `Custom of string | `Firehose | `Sample ] -> 
  unit Lwt.t * Twitterstream_status.t Lwt_stream.t

