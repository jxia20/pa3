(* heat_distributed.ml *)
open Common
open Join

type role =
  | Master
  | Worker

let role =
  if Array.length Sys.argv > 1 && Sys.argv.(1) = "master"
  then Master
  else Worker

let port =
  if role = Worker && Array.length Sys.argv > 2
  then int_of_string Sys.argv.(2)
  else 0

let run_worker port =
  (* Define a synchronous channel compute_remote *)
  let _ =
    def compute_remote (y0, y1, curr) =
      (* allocate next grid *)
      let next = Array.init n (fun _ -> Array.make n 0.0) in

      (* copy boundaries from curr to next *)
      for x = 0 to n - 1 do
        next.(0).(x) <- curr.(0).(x);
        next.(n - 1).(x) <- curr.(n - 1).(x)
      done;

      for y = 0 to n - 1 do
        next.(y).(0) <- curr.(y).(0);
        next.(y).(n - 1) <- curr.(y).(n - 1)
      done;

      (* compute interior rows y0 to y1 *)
      compute_tile ~curr ~next ~y0 ~y1;

      (* build partial rows *)
      let row_count = y1 - y0 + 1 in
      let partial = Array.init row_count (fun _ -> Array.make n 0.0) in

      for j = 0 to row_count - 1 do
        let y = y0 + j in
        Array.blit next.(y) 0 partial.(j) 0 n
      done;

      reply (y0, y1, partial) to compute_remote
    in

    (* Register this synchronous channel under the heat worker *)
    Join.Ns.register Join.Ns.here "heat_worker"
      (compute_remote :
         int * int * grid -> int * int * (float array array));

    (* Listen on all interfaces on the given port *)
    Join.Site.listen
      (Unix.ADDR_INET (Unix.inet_addr_any, port));

    (* Keep the worker alive forever *)
    let rec loop () =
      Thread.delay 1.0;
      loop ()
    in
    loop ()
  in
  ()

type worker_fun =
  (int * int * grid) -> (int * int * (float array array))

let connect_worker host port : worker_fun =
  let server_addr = Unix.gethostbyname host in
  let site =
    Join.Site.there
      (Unix.ADDR_INET (server_addr.Unix.h_addr_list.(0), port))
  in
  let ns = Join.Ns.of_site site in
  (Join.Ns.lookup ns "heat_worker"
     : int * int * grid -> int * int * (float array array))

let curr_ref = ref (create_grid ())
let next_ref = ref (create_grid ())

let swap_buffers () =
  let tmp = !curr_ref in
  curr_ref := !next_ref;
  next_ref := tmp

let run_master () =
  let worker_ports = [|9001; 9002; 9003; 9004|] in

  let workers =
    Array.map (fun p -> connect_worker "localhost" p) worker_ports
  in

  let num_workers = Array.length workers in

  let tiles = Array.of_list (split_rows num_workers) in

  for t = 1 to steps do
    for i = 0 to num_workers - 1 do
      let (y0, y1) = tiles.(i) in
      let f = workers.(i) in

      let (_y0, _y1, partial) = f (y0, y1, !curr_ref) in

      let row_count = Array.length partial in
      for j = 0 to row_count - 1 do
        let y = y0 + j in
        Array.blit partial.(j) 0 (!next_ref).(y) 0 n
      done
    done;

    let curr = !curr_ref in
    let next = !next_ref in

    for x = 0 to n - 1 do
      next.(0).(x) <- curr.(0).(x);
      next.(n - 1).(x) <- curr.(n - 1).(x)
    done;

    for y = 0 to n - 1 do
      next.(y).(0) <- curr.(y).(0);
      next.(y).(n - 1) <- curr.(y).(n - 1)
    done;

    swap_buffers ()
  done;

  write_grid !curr_ref "out_distributed.txt"

let () =
  match role with
  | Master -> run_master ()
  | Worker -> run_worker port
