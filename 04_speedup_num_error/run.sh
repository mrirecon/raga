#!/bin/bash

set -euxB


# Avoid limitation by network traffic
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Traj creation

BR=200
SPOKES=377
TIME=100


# Golden Angle based Sampling pattern

NUM_GA=1
bart traj -x$BR -y $SPOKES -G -r --double-base -s $NUM_GA -t $TIME $TMP_DIR/traj_ga

bart phantom -k -t $TMP_DIR/traj_ga $TMP_DIR/k_ga

# Reshape data and trajectory

REBIN=29
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
/usr/bin/time -v bart nufft -i $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/reco_ga &> data

ET=$(date +%s.%3N)
T=$(echo "${ET}-${ST}" | bc)

HWM=$(grep "Maximum resident set size (kbytes):" data | sed -E 's/.*: (\d*)/\1/g')

rm data


# RAGA Sampling Pattern N=2, i=12, doubled angle

bart traj -x$BR -y $SPOKES -A -G -r --double-base -s $NUM_GA $TMP_DIR/traj_raga

# Sampling which repeats in time
bart repmat 10 $TIME $TMP_DIR/traj_raga $TMP_DIR/traj_raga_time

bart phantom -k -t $TMP_DIR/traj_raga_time $TMP_DIR/k_raga

# Reshape data and trajectory
LOOP_DIM=11
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

/usr/bin/time -v bart nufft -i $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/_reco_raga &> data

bart reshape $(bart bitmask 10 $LOOP_DIM) $((BINTIME*TIME)) 1 $TMP_DIR/_reco_raga $TMP_DIR/reco_raga

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

id=0
export CUDA_VISIBLE_DEVICES=${id}


[ -f log_gpu_ga.log ] && rm log_gpu_ga.log

nvidia-smi --id=${id} --query-gpu=memory.used --format=csv --loop-ms=100 > log_gpu_ga.log &
# nvidia-smi --id=${id} --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv --loop-ms=100 > log_gpu.log &

PID=$!

ST=$(date +%s.%3N)

bart nufft -i -g $TMP_DIR/traj_ga_rb $TMP_DIR/k_ga_rb $TMP_DIR/reco_ga

ET=$(date +%s.%3N)
T_GPU=$(echo "${ET}-${ST}" | bc)

kill $PID



# Reconstruction of RAGA

[ -f log_gpu_raga.log ] && rm log_gpu_raga.log

nvidia-smi --id=${id} --query-gpu=memory.used --format=csv --loop-ms=100 > log_gpu_raga.log &

PID=$!


ST=$(date +%s.%3N)

bart nufft -g -i $TMP_DIR/traj_raga_rb $TMP_DIR/k_raga_rb $TMP_DIR/_reco_raga

bart reshape $(bart bitmask 10 $LOOP_DIM) $((BINTIME*TIME)) 1 $TMP_DIR/_reco_raga $TMP_DIR/reco_raga

ET=$(date +%s.%3N)
T2_GPU=$(echo "${ET}-${ST}" | bc)

kill $PID


# Print Result
echo -e "GPU Reconstructions\n"
echo -e "NRMSE of both reconstructions:\t$(bart nrmse $TMP_DIR/reco{_ga,_raga})"
echo -e "Elapsed Runtime:\t GA: ${T_GPU} s\tRAGA: ${T2_GPU} s"
echo -e "High Water Mark:\t${HWM} kbyte\tLoop: ${HWM2} kbyte\n\n"


[ -f data.txt ] && rm data.txt
touch data.txt

echo -e "${T}\t${T2}\n${T_GPU}\t${T2_GPU}\n${HWM}\t${HWM2}" >> data.txt


[ -d $TMP_DIR ] && rm -rf $TMP_DIR
