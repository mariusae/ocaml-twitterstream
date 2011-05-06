(**
 Twitter message definitions.
 @author marius a. eriksen
 *)

type status =
  < text : string;
    favorited : bool;
    user : <
      statuses_count : int;
      created_at : string;
      followers_count : int;
      profile_image_url : string option;
      url : string option;
      name : string;
      id : int;
      screen_name : string
    >
  >

type parsed_message = Status of status | Delete of (int * int) | Parsefail
type message = string * parsed_message
type t = message

val of_json_string : string -> message
