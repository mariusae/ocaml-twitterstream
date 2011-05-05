open Json_type

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

let point_of_geo_object = function
  | Object geo -> begin
      try
        let geo_type = List.assoc "type" geo;
        and coords = List.assoc "coordinates" geo in
        match geo_type, coords with
          | String "Point", Array [Float y; Float x] -> Some (x, y)
          | _ -> None
      with Not_found -> None
    end
  | _ -> None

let place_type_of_string = function
  | "neighborhood" -> `Neighborhood
  | "city"         -> `City
  | "admin"        -> `Admin
  | "country"      -> `Country
  | _              -> raise Not_found

let bounding_box_of_place place = 
  match List.assoc "bounding_box" place with
    | Object bb -> begin
        match List.assoc "coordinates" bb with
          | Array [Array [Array [Float x0; Float y0];
                          Array [Float x1; Float y1];
                          Array [Float x2; Float y2];
                          Array [Float x3; Float y3]]] -> 
              (x0, y0), (x1, y1), (x2, y2), (x3, y3)
          | _ -> raise (Json_error "invalid coordinates")
      end
    | _ -> raise Not_found

let place_of_place_object = function
  | Object place ->
    begin
      try Some {
        place_id = Browse.string (List.assoc "id" place);
        place_type = place_type_of_string
          (Browse.string (List.assoc "place_type" place));
        place_name = Browse.string (List.assoc "full_name" place);
        bounding_box = bounding_box_of_place place
      } with Not_found | Json_error _ -> None
    end
  | _ -> None

let of_json_string s =
  let j =
    try  Some (Json_io.json_of_string s)
    with Failure _ | Json_error _ -> None in
  let message =
    match j with
      | Some (Object o) when List.mem_assoc "delete" o -> begin
          try let del = Browse.objekt (List.assoc "delete" o) in Delete (
            Browse.int (List.assoc "id" del),
            Browse.int (List.assoc "user_id" del)
          ) with Json_error _ | Not_found -> Parsefail
        end
      | Some (Object o) -> begin
          let t = Browse.make_table o in
          try Status {
            id   = Browse.int    (Browse.field t "id");
            text = Browse.string (Browse.field t "text");
            geo  = {
              place = place_of_place_object (Browse.fieldx t "place");
              point = point_of_geo_object   (Browse.fieldx t "geo")
            }
          } with Json_error _ -> Parsefail
        end
      | _ -> Parsefail in
  s, message
