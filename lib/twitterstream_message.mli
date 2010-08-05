type place = {
  place_id     : string;
  place_type   : [`Neighborhood | `City | `Admin | `Country];
  place_name   : string;
  bounding_box : (float * float) * (float * float) *
                 (float * float) * (float * float);
}

type geo = {
  place : place option;
  point : (float * float) option;
}

type status = {
  id   : int;
  text : string;
  geo  : geo;
}

type parsed_message = Status of status | Delete of (int * int) | Parsefail
type message = string * parsed_message
type t = message

val of_json_string : string -> message
