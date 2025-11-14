(* heat_concurrent.ml *)
open Common;;

(* These are the 2 grids that will swap on each step *)
let curr_ref = ref (create_grid ());;
let next_ref = ref (create_grid ());;

(* swap the references which is cheaper *)
let swap_buffers () =
  let tmp = !curr_ref in
  curr_ref := !next_ref;
  next_ref := tmp
;;

(* choose number of tiles, use env var NUM_TILES as override *)
let tiles =
  let t =
    try int_of_string (Sys.getenv "NUM_TILES")
    with _ -> 4
  in
  split_rows t
;;

(* wait for n ticks, then wait() returns *)
let make_barrier n =
  def count(k) & tick() = count(k-1)
   or count(0) & wait() = reply () to wait in
  spawn count(n) ;
  tick, wait
;;

(* run all time steps *)
let rec run t =
  if t > steps then
    (* done *)
    write_grid !curr_ref "out_concurrent.txt"
  else begin
    (* new barrier for this step *)
    let tick, wait = make_barrier (List.length tiles) in

    (* spawn one worker per tile *)
    List.iter
      (fun (y0, y1) ->
         spawn begin
           let curr = !curr_ref
           and next = !next_ref in
           compute_tile ~curr ~next ~y0 ~y1;
           (* we are now in process context, so this async send is OK *)
           tick()
         end
      )
      tiles;

    (* wait until all tiles finish this step *)
    ignore (wait ());

    (* swap buffers and keep going *)
    swap_buffers ();
    run (t + 1)
  end
;;

let () = run 1 ;;
