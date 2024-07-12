#!/bin/bash

set -euBx
set -o pipefail

# Avoid limitation by network traffic
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
# TMP_DIR="."

source opts.sh

# ################################################
# Golden Ratio Pattern N=2, doubled angle
# ################################################

bart traj -x$BR -y $SPOKES -G -r --double-base -o $OS -s $NUM_GA -t $TIME $TMP_DIR/traj_ga

bart phantom -s$COILS -k -t $TMP_DIR/traj_ga $TMP_DIR/k_ga

# Reshape data and trajectory

BINTIME=$(($((SPOKES*TIME))/REBIN))

bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) $TMP_DIR/traj_ga $TMP_DIR/_t2
bart extract 10 0 $((BINTIME*REBIN)) $TMP_DIR/_t2 $TMP_DIR/_t3

bart reshape $(bart bitmask 2 10) $REBIN $BINTIME $TMP_DIR/_t3 $TMP_DIR/traj_ga_rb
rm $TMP_DIR/_t{2,3}.{cfl,hdr}

bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) $TMP_DIR/k_ga $TMP_DIR/_k2
bart extract 10 0 $((BINTIME*REBIN)) $TMP_DIR/_k2 $TMP_DIR/_k3

bart reshape $(bart bitmask 2 10) $REBIN $BINTIME $TMP_DIR/_k3 $TMP_DIR/k_ga_rb
rm $TMP_DIR/_k{2,3}.{cfl,hdr}


# ################################################
# RAGA Sampling Pattern N=2, i=12, doubled angle
# ################################################

bart traj -x$BR -y $SPOKES -A -G -r -o $OS --double-base -s $NUM_GA $TMP_DIR/traj_raga

# Sampling which repeats in time
bart repmat 10 $TIME $TMP_DIR/traj_raga $TMP_DIR/traj_raga_time

bart phantom -s$COILS -k -t $TMP_DIR/traj_raga_time $TMP_DIR/k_raga

# Reshape data and trajectory
BINTIME=$((SPOKES/REBIN))

# bart reshape $(bart bitmask 2 $LOOP_DIM) 1 $SPOKES 
bart extract 2 0 $((BINTIME*REBIN)) $TMP_DIR/traj_raga $TMP_DIR/_t2

bart reshape $(bart bitmask 2 $LOOP_DIM) $REBIN $BINTIME $TMP_DIR/_t2 $TMP_DIR/traj_raga_rb
rm $TMP_DIR/_t2.{cfl,hdr}

bart extract 2 0 $((BINTIME*REBIN)) $TMP_DIR/k_raga $TMP_DIR/_k2

bart reshape $(bart bitmask 2 $LOOP_DIM) $REBIN $BINTIME $TMP_DIR/_k2 $TMP_DIR/k_raga_rb
rm $TMP_DIR/_k2.{cfl,hdr}

# Grid trajectory
bart calc zround $TMP_DIR/traj_ga_rb $TMP_DIR/traj_ga_grid

bart calc zround $TMP_DIR/traj_raga_rb $TMP_DIR/traj_raga_grid

# Multiple runs to analyze

NUM_RUNS=10

for i in `seq 0 $((NUM_RUNS-1))`;
do
	# -------------------------------------
	#   GROG Gridding of Full Timeseries (Golden Ratio)
	# -------------------------------------

	[ -f file_ga ] && rm file_ga
	touch file_ga

	DEBUG_LEVEL=3 bart grog -s 300 $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/traj_ga_grid $TMP_DIR/k_ga_grid > file_ga 

	# -------------------------------------
	#   GROG Gridding of Repeating Timeseries (RAGA)
	# -------------------------------------

	[ -f file_raga ] && rm file_raga
	touch file_raga

	DEBUG_LEVEL=3 bart grog -s 300 $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/traj_raga_grid $TMP_DIR/k_raga_grid > file_raga 

	# Write runtimes to file
	bart vec $(cat file_ga | grep "Time for calibration" | cut -d " " -f 4) 	\
		$(cat file_ga | grep "Time for gridding" | cut -d " " -f 4) 		\
		$(cat file_raga | grep "Time for calibration" | cut -d " " -f 4) 	\
		$(cat file_raga | grep "Time for gridding" | cut -d " " -f 4)		\
		grog_run_$(printf "%03.0f" $i)

	rm file_ga file_raga
done

bart join 2 $(ls grog_run_*.cfl | sed -e 's/\.cfl//') grog

rm grog_run_*.{cfl,hdr}
