Alex Rougebec rougea
Jimi Xia xiaj4

Build and Run Instructions

Control the number of row tiles with env var NUM_TILES (default 4)

Sequential

Compile:
ocamlc -o heat_seq common.ml seq_baseline.ml

Run:
./heat_seq

Output:
out_seq.txt

Concurrent

Compile:
jocamlc -o heat_concurrent common.ml heat_concurrent.ml

Run:
./heat_concurrent

Output:
out_concurrent.txt

Distributed

Compile:
jocamlc -o heat_distributed common.ml heat_distributed.ml

Start Workers:
./heat_distributed worker 9001 &
./heat_distributed worker 9002 &
./heat_distributed worker 9003 &
./heat_distributed worker 9004 &

Start Master:
./heat_distributed master

Output:
out_distributed.txt

Verifying correctness:
diff out_seq.txt out_concurrent.txt
diff out_seq.txt out_distributed.txt

Cleaning up workers:
ps aux | grep heat_distributed
pkill <pid>

Problem Definition:
	The grid size is 122 x 122
	The initial condition is that left boundary (x=0) is 100.0 for rows y=31 to 90 and 20.0 elsewhere.
	Jacobi update rule states that each interior cell (y,x) becomes the average of its 
    four neighbors from the previous time step while the boundary cells remain constant.
	Steps = 1024

Design Notes: 
  We use double buffered grids with shared helpers in common.ml
  (n=122, steps=1024, create_grid, write_grid, split_rows, compute_tile).
  In sequential, the baseline swaps buffers each step. The concurrent version tiles interior rows and
  spawns one JoCaml process per tile per step, a join-calculus barrier guarantees
  all tiles finish before swapping. The distributed version is Master and Worker. Each worker exposes
  a synchronous compute_remote. The master calls each worker, copies returned rows into next,
  reapplies fixed boundaries, and swaps. 

Performance Analysis: 
  With N = 122×122 cells and workers = W, the compute per step per worker is about C·N/W, 
  so distributed wins only when networks are fast and W is not huge. 
  Because the master’s RPCs are serialized, overlap is minimal even with many workers. 
  Two fixes make parallel computing much faster:
  asking all workers at once and then waiting on the replies and
  sending only a chunk of the grid to each worker and only swaps the border rows it needs 
  with the master and other workers when needed on each step.

Features/Limitations
Features
	Correct sequential baseline with fixed boundaries.
  Join calculus barrier for deterministic, per-step synchronization in the concurrent version.
	Distributed Master and Worker using JoCaml name service and multiple workers supported via ports.
	Identical text output format across all modes which are all compatible with the Python viewer.

Limitations
	Sequential RPCs in master: worker calls are issued one-by-one, change to concurrent RPCs to fully gain parallel speedups.
	Each worker receives the entire grid which is inefficient
	No dynamic worker discovery since hosts and ports are hardcoded.
