(* a pretty silly sample app to just dump textual tweets on the console *)

open Lwt
open Printf

let () =
  let auth = 
    match (Array.to_list Sys.argv) with
      | _ :: username :: password :: _ -> username, password
      | name :: _ -> invalid_arg (sprintf "usage: %s USERNAME PASSWORD" name)
      | _ -> failwith "impossible!"
  in
  
  Lwt_log.Section.set_level Lwt_log.Section.main Lwt_log.Info;
  let t, stream = Twitterstream_stream.open_stream auth `Sample in
  
  let open Twitterstream_message in
  let tt = for_lwt status in stream do
    match status with
      | (_, Status status) -> Lwt_log.info status#text
      | _ -> return ()
  done in

  Lwt_main.run (join [t; tt])