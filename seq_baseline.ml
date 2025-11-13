let n = 122
let steps = 1024

let create_grid () =
  Array.init n (fun y ->
    Array.init n (fun x ->
      if x = 0 && y > 30 && y < 91 then 100.0 else 20.0))

let update curr next =
  for y = 1 to n - 2 do
    for x = 1 to n - 2 do
      next.(y).(x) <- 0.25 *. (curr.(y-1).(x) +. curr.(y+1).(x)
                             +. curr.(y).(x-1) +. curr.(y).(x+1))
    done
  done

let swap a b = (a := !b; b := !a)

let write_grid grid filename =
  let oc = open_out filename in
  Array.iter (fun row ->
    Array.iteri (fun i v ->
      if i>0 then output_char oc ' ';
      Printf.fprintf oc "%.2f" v) row;
    output_char oc '\n') grid;
  close_out oc

let () =
  let curr = ref (create_grid ()) in
  let next = ref (create_grid ()) in
  for t = 1 to steps do
    update !curr !next;
    let tmp = !curr in curr := !next; next := tmp
  done;
  write_grid !curr "out_seq.txt"
