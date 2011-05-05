Twitter streaming for OCaml
===========================

An interface to the
[Twitter streaming API](http://dev.twitter.com/pages/streaming_api)
for [OCaml](http://caml.inria.fr/). The main interface is through an
[LWT](http://ocsigen.org/lwt/) stream and can thus be used in
conjuction with other LWT code.

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

The first form - `stream_of_channel` - yields an LWT `stream` from an
arbitrary LWT channel (eg. a streaming dump on disk). The second form
establishes a new HTTP stream using `Cohttp`.
