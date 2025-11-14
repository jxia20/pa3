Alex Rougebec. Jimi Xia

Build and Run Instructions

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