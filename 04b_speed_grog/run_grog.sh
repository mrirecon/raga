#!/bin/bash



set -euxB
set -o pipefail

OUT=$1

source opts.sh

[[ -d log ]] && rm -rf log
mkdir log


# Avoid limitation by network traffic
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
# TMP_DIR="."

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

# -------------------------------------
# Reconstruct of RAGA (nuFFT-based)
# -------------------------------------
# [ -f data ] && rm data
# touch data

# ST=$(date +%s.%3N)
# #-v
# DEBUG_LEVEL=4 /usr/bin/time -alh bart pics $FLAGS -e -S -RT:7:0:0.0008 -t $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/sens $TMP_DIR/_reco_raga &> data

# bart reshape $(bart bitmask $LOOP_DIM 10) 1 $((BINTIME*TIME)) $TMP_DIR/_reco_raga $TMP_DIR/reco_raga

# ET=$(date +%s.%3N)
# T2=$(echo "${ET}-${ST}" | bc)

# # HWM2=$(grep "Maximum resident set size (kbytes):" data | sed -E 's/.*: (\d*)/\1/g')

# rm data


# -------------------------------------
#   GROG Gridding of Full Timeseries (Golden Ratio)
# -------------------------------------

/scratch/nscho/bart/bart grog -s 300 --measure-time time_ga $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/traj_ga_grid $TMP_DIR/k_ga_grid

# -------------------------------------
#   GROG Gridding of Repeating Timeseries (RAGA)
# -------------------------------------

/scratch/nscho/bart/bart grog -s 300 --measure-time time_raga $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/traj_raga_grid $TMP_DIR/k_raga_grid


# Write runtimes to file
bart join 0 time_ga time_raga $OUT