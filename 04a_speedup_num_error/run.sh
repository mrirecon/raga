#!/bin/bash

set -euBx
set -o pipefail

[[ -d log ]] && rm -rf log

NUM_RUNS=10

for i in `seq 0 $((NUM_RUNS-1))`;
do
	./run_nufft.sh '' nufft_run_$(printf "%03.0f" $i)

	./run_nufft.sh '-r' nufft_nt_run_$(printf "%03.0f" $i)

	# ./run_pics.sh '' pics
	# ./run_nlinv.sh '' nlinv
done

bart join 2 $(ls nufft_run_*.cfl | sed -e 's/\.cfl//') nufft
bart join 2 $(ls nufft_nt_run_*.cfl | sed -e 's/\.cfl//') nufft_nt

bart join 1 nufft nufft_nt joined_data

rm nufft_run_*.{cfl,hdr}
rm nufft_nt_run_*.{cfl,hdr}