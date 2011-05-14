open Json_type

type json status =
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

let of_json_string s =
  try
    let j = Json_io.json_of_string s in
    let status = status_of_json j in
    s, Status status
  with Failure _ | Json_error _ -> s, Parsefail


