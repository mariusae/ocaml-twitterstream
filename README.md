# Twitter streaming for OCaml

An interface to the
[Twitter streaming API](http://dev.twitter.com/pages/streaming_api)
for [OCaml](http://caml.inria.fr/). The main interface is through an
[LWT](http://ocsigen.org/lwt/) stream and can thus be used in
conjuction with other LWT code.

    val of_channel : 
      Lwt_io.input Lwt_io.channel -> 
      unit Lwt.t * Twitterstream_message.t Lwt_stream.t

    val of_http_stream : 
      string * string -> 
      [< `Custom of string | `Firehose | `Sample ] -> 
      unit Lwt.t * Twitterstream_message.t Lwt_stream.t

The first form - `of_channel` - yields an LWT `stream` from an
arbitrary LWT channel (eg. a streaming dump on disk). The second form
establishes a new HTTP stream.

In lieu of an LWT compatible HTTP client, the library forks another
process and pushes messages over a Unix pipe.
