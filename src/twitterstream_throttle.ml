open Lwt

type state = {
  last_connect_time  : float;
  reconnect_interval : float;
  num_attempts       : int;
  max_attempts       : int;
}

let make ~initial_reconnect_interval ~max_attempts = {
  last_connect_time = 0.;
  reconnect_interval = initial_reconnect_interval;
  num_attempts = 0;
  max_attempts
}

let wait state =
  if state.num_attempts = 0 then
    let state' = { state with 
      num_attempts = 1;
      last_connect_time = Unix.time ()
    } in
    return (Some state')
  else if state.num_attempts = state.max_attempts then
    return None
  else
    Lwt_unix.sleep state.reconnect_interval >>
    let state' = { state with
      num_attempts       = state.num_attempts + 1;
      reconnect_interval = state.reconnect_interval *. 2.;
      last_connect_time  = Unix.time ()
    } in
    return (Some state')

