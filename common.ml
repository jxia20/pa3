(* common.ml *)
let n = 122
let steps = 1024

type grid = float array array

let create_grid () : grid =
  Array.init n (fun y ->
    Array.init n (fun x ->
      if x = 0 && y > 30 && y < 91 then 100.0 else 20.0))

let write_grid (g:grid) (filename:string) =
  let oc = open_out filename in
  Array.iter (fun row ->
    Array.iteri (fun i v ->
      if i > 0 then output_char oc ' ';
      Printf.fprintf oc "%.2f" v) row;
    output_char oc '\n') g;
  close_out oc

(* compute one tile of interior rows [y0..y1], cols 1..n-2 *)
let compute_tile ~(curr:grid) ~(next:grid) ~(y0:int) ~(y1:int) =
  for y = y0 to y1 do
    for x = 1 to n - 2 do
      next.(y).(x) <-
        0.25 *. ( curr.(y-1).(x) +. curr.(y+1).(x)
                +. curr.(y).(x-1) +. curr.(y).(x+1) )
    done
  done

(* split interior rows 1..n-2 into ~equal tiles *)
let split_rows (tiles:int) : (int * int) list =
  let total = (n - 2) in       (* rows 1..120 = 120 rows *)
  let base = total / tiles in
  let extra = total mod tiles in
  let acc = ref [] in
  let y = ref 1 in
  for i = 0 to tiles - 1 do
    let len = base + (if i < extra then 1 else 0) in
    let y0 = !y in
    let y1 = !y + len - 1 in
    acc := (y0, y1) :: !acc;
    y := y1 + 1
  done;
  List.rev !acc
