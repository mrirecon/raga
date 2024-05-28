#!/bin/bash

set -euBx
set -o pipefail

NUM_RUNS=10

for i in `seq 0 $((NUM_RUNS-1))`;
do
	./run_grog.sh grog_run_$(printf "%03.0f" $i)
done

bart join 2 $(ls grog_run_*.cfl | sed -e 's/\.cfl//') grog

rm grog_run_*.{cfl,hdr}
