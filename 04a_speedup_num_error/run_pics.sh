#!/bin/bash

set -euxB
set -o pipefail

FLAGS=$1
OUT=$2

source opts.sh

# Avoid limitation by network traffic
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Traj creation

# Golden Angle based Sampling pattern

bart traj -x$BR -y $SPOKES -G -r --double-base -s $NUM_GA -t $TIME $TMP_DIR/traj_ga

bart phantom -s$COILS -k -t $TMP_DIR/traj_ga $TMP_DIR/k_ga


# Coil Estimation

bart extract 10 $((TIME-3)) $TIME $TMP_DIR/traj_ga $TMP_DIR/tmp_t
bart extract 10 $((TIME-3)) $TIME $TMP_DIR/k_ga $TMP_DIR/tmp_k

bart nufft -d$BR:$BR:1 -i -g -t $TMP_DIR/tmp_t $TMP_DIR/tmp_k $TMP_DIR/psf

bart fft -u $(bart bitmask 0 1 2) $TMP_DIR/psf $TMP_DIR/pattern

bart ecalib -c 0 -m 1 $TMP_DIR/pattern $TMP_DIR/sens

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

# Reconstruction for GA

[ -f data ] && rm data
touch data

ST=$(date +%s.%3N)

# High Water Mark
DEBUG_LEVEL=4 /usr/bin/time -v bart pics $FLAGS -e -S -RT:7:0:0.0008 -t $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/sens $TMP_DIR/reco_ga &> data

ET=$(date +%s.%3N)
T=$(echo "${ET}-${ST}" | bc)

HWM=$(grep "Maximum resident set size (kbytes):" data | sed -E 's/.*: (\d*)/\1/g')

rm data


# RAGA Sampling Pattern N=2, i=12, doubled angle

bart traj -x$BR -y $SPOKES -A -G -r --double-base -s $NUM_GA $TMP_DIR/traj_raga

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

# Reconstruct of RAGA

[ -f data ] && rm data
touch data

ST=$(date +%s.%3N)

DEBUG_LEVEL=4 /usr/bin/time -v bart pics $FLAGS -e -S -RT:7:0:0.0008 -t $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/sens $TMP_DIR/_reco_raga &> data

bart reshape $(bart bitmask $LOOP_DIM 10) 1 $((BINTIME*TIME)) $TMP_DIR/_reco_raga $TMP_DIR/reco_raga

ET=$(date +%s.%3N)
T2=$(echo "${ET}-${ST}" | bc)

HWM2=$(grep "Maximum resident set size (kbytes):" data | sed -E 's/.*: (\d*)/\1/g')

rm data

# Print Result
echo -e "CPU Reconstructions\n"
echo -e "NRMSE of both reconstructions:\t$(bart nrmse $TMP_DIR/reco{_ga,_raga})"
echo -e "Elapsed Runtime:\t GA: ${T} s\tRAGA: ${T2} s"
echo -e "High Water Mark:\t${HWM} kbyte\tLoop: ${HWM2} kbyte\n\n"

###############################
# GPU Reconstructions
###############################

# Reconstruction for GA

# Memory Usage on GPU

export CUDA_VISIBLE_DEVICES=${id}

[[ ! -d log ]] && mkdir log


[ -f log/log_gpu_ga_${OUT}.log ] && rm log/log_gpu_ga_${OUT}.log

nvidia-smi --id=${id} --query-gpu=memory.used --format=csv --loop-ms=100 > log/log_gpu_ga_${OUT}.log &
# nvidia-smi --id=${id} --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv --loop-ms=100 > log_gpu.log &

PID=$!

ST=$(date +%s.%3N)

# bart nufft -i -g $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/reco_ga
DEBUG_LEVEL=4 bart pics $FLAGS -e -g -S -RT:7:0:0.0008 -t $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/sens $TMP_DIR/reco_ga

ET=$(date +%s.%3N)
T_GPU=$(echo "${ET}-${ST}" | bc)

kill $PID



# Reconstruction of RAGA

[ -f log/log_gpu_raga_${OUT}.log ] && rm log/log_gpu_raga_${OUT}.log

nvidia-smi --id=${id} --query-gpu=memory.used --format=csv --loop-ms=100 > log/log_gpu_raga_${OUT}.log &

PID=$!


ST=$(date +%s.%3N)

# bart nufft -g -i $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/_reco_raga
DEBUG_LEVEL=4 bart pics $FLAGS -e -g -S -RT:7:0:0.0008 -t $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/sens $TMP_DIR/_reco_raga

bart reshape $(bart bitmask $LOOP_DIM 10) 1 $((BINTIME*TIME)) $TMP_DIR/_reco_raga $TMP_DIR/reco_raga

ET=$(date +%s.%3N)
T2_GPU=$(echo "${ET}-${ST}" | bc)

kill $PID


# Print Result
echo -e "GPU Reconstructions\n"
echo -e "NRMSE of both reconstructions:\t$(bart nrmse $TMP_DIR/reco{_ga,_raga})"
echo -e "Elapsed Runtime:\t GA: ${T_GPU} s\tRAGA: ${T2_GPU} s"
echo -e "High Water Mark:\t${HWM} kbyte\tLoop: ${HWM2} kbyte\n\n"


bart vec -- ${T} ${T2} ${T_GPU} ${T2_GPU} ${HWM} ${HWM2} $OUT


[ -d $TMP_DIR ] && rm -rf $TMP_DIR
