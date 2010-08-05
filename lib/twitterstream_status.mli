type place = {
  place_id     : string;
  place_type   : [`Neighborhood | `City | `Admin | `Country];
  bounding_box : (float * float) * (float * float) *
                 (float  * float) * (float * float);
}

type geo = {
  place : place option;
  point : (float * float) option;
}

type t = {
  id   : int;
  text : string;
  geo  : geo;
  json : string;
}

val of_json_string : string -> t option
