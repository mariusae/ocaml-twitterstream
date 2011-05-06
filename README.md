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

# Example stream counter.

    open Lwt

    let setup_logging () =
      let open Lwt_log in
      default := channel
        ~close_mode:`Keep
        ~channel:Lwt_io.stderr
        ();
      Section.set_level Section.main Debug

    let () =
      setup_logging ();
     
      let t, stream =
        Twitterstream_stream.open_stream
          ~max_tries:2 ("username", "password") `Firehose in
     
      let count = ref 0 in
     
      let tt = for_lwt status in stream do
        let open Twitterstream_message in
        let orig, message = status in 
        match message with
          | Status status ->
              let user = status#user in
              Lwt_log.info_f "%s(%d): %s"
                user#screen_name user#followers_count
                status#text
          | Delete _ -> return ()
          | Parsefail -> Lwt_log.info_f "failed to parse %s" orig 
      done in
       
      Lwt_main.run (Lwt.join [t; tt])
