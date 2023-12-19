#!/bin/bash

set -eux


DATA=(
	data_bin_raga
	data_bin_ga
	)

TRAJ=(
	RAGA
	GA
	)

for i in `seq 0 $((${#DATA[@]}-1))`
do
	bart cc -p 5 data/"${DATA[$i]}" ksp

	SAMPLES=$(bart show -d 0 ksp)
	BR=$((SAMPLES/2))
	SPOKES=$(bart show -d 1 ksp)
	COILS=$(bart show -d 3 ksp)
	TIME=$(bart show -d 10 ksp)

	bart transpose 1 2 ksp tmp
	bart transpose 0 1 tmp __k
	rm {tmp,ksp}.{cfl,hdr}


	# Trajectory with Gradient Delay correction

	NUM_GA=1

	if [[ "${TRAJ[$i]}" == "RAGA" ]] ;
	then
		bart traj -x $SAMPLES -y $SPOKES -r -D _t3
		bart repmat 10 $TIME _t3 _t
		rm _t3.{cfl,hdr}

	elif [[ "${TRAJ[$i]}" == "GA" ]]
	then
		bart traj -x $SAMPLES -y $SPOKES -r -G -s $NUM_GA -t $TIME _t
	else
		echo "Choose either GA or RAGA trajectory!"
		exit 1
	fi

	bart extract 10 $((TIME-2)) $((TIME-1)) _t tmp_t
	bart extract 10 $((TIME-2)) $((TIME-1)) __k tmp_k
	rm _t.{cfl,hdr}

	if [[ "${TRAJ[$i]}" == "RAGA" ]] ;
	then
		bart traj -x $SAMPLES -y $SPOKES -r -D -O -q $(bart estdelay -R tmp_t tmp_k) _t3
		bart repmat 10 $TIME _t3 _t2
		rm _t3.{cfl,hdr}

	elif [[ "${TRAJ[$i]}" == "GA" ]]
	then
		bart traj -x $SAMPLES -y $SPOKES -r -G -s $NUM_GA -t $TIME -O -q $(bart estdelay -R tmp_t tmp_k) _t2
	else
		echo "Choose either GA or RAGA trajectory!"
		exit 1
	fi
	
	rm tmp_{t,k}.{cfl,hdr}


	bart scale 0.5 _t2 __t
	rm _t2.{cfl,hdr}

	# Rebin RAGA trajectory to temporal ordering

	if [[ "${TRAJ[$i]}" == "RAGA" ]] ;
	then
		bart transpose 1 2 data/data_bin_raga_ind ind
		bart slice 10 0 ind ind2
		rm ind.{cfl,hdr}

		bart bin -o ind2 __t _t
		bart bin -o ind2 __k _k
		rm ind2.{cfl,hdr}

	elif [[ "${TRAJ[$i]}" == "GA" ]]
	then
		bart copy __t _t
		bart copy __k _k
	else
		echo "Choose either GA or RAGA trajectory!"
		exit 1
	fi
	rm __{t,k}.{cfl,hdr}

	# Reshape data and trajectory

	REBIN=21
	BINTIME=$(($((SPOKES*TIME))/REBIN))

	bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) _t _t2
	bart extract 10 0 $((BINTIME*REBIN)) _t2 _t3

	bart reshape $(bart bitmask 2 10) $REBIN $BINTIME _t3 _t4
	rm _t{,2,3}.{cfl,hdr}

	bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) _k _k2
	bart extract 10 0 $((BINTIME*REBIN)) _k2 _k3

	bart reshape $(bart bitmask 2 10) $REBIN $BINTIME _k3 _k4
	rm _k{,2,3}.{cfl,hdr}


	# Extract Frames covering ~ 4s for T1 mapping

	TIME_STEPS=65

	bart extract 10 0 ${TIME_STEPS} _k4 _k5 
	bart extract 10 0 ${TIME_STEPS} _t4 _t5
	rm _{t,k}4.{cfl,hdr}

	# Move time dimension for (10) -> (5) as required by moba

	bart transpose 5 10 _k5 k
	bart transpose 5 10 _t5 t
	rm _{t,k}5.{cfl,hdr}

	# Create inversion time (required for Look-Locker model)

	TR=0.0029

	bart index 5 ${TIME_STEPS} _TI

	bart scale $(echo "${TR}*${REBIN}" | bc) _TI{,s}

	bart ones 6 1 1 1 1 1 ${TIME_STEPS} _one

	bart saxpy $(echo "${TR}*$((REBIN/2))" | bc) _one _TIs TI

	rm _TI{,s}.{cfl,hdr} _one.{cfl,hdr}

	# Run moba reconstruction

	ITER=10
	INNER_ITER=250
	STEP_SIZE=0.95
	MIN_R1=0.001
	OS=1
	REDU_FAC=3
	LAMBDA=0.0005
	FA=8

	nice -5 bart moba -L \
	--img_dims $BR:$BR:1 \
	-i$ITER -C$INNER_ITER -s$STEP_SIZE -B$MIN_R1 -d4 -o$OS -R$REDU_FAC -j$LAMBDA -g -N \
	--other pinit=1:1:2:1 --scale_data=5000. --scale_psf=1000. --normalize_scaling \
	-t t k TI reco sens


	# Post-Process

	DELAY=0.015
	M0_THRESH=0.1

	bart looklocker -t $M0_THRESH -D $DELAY reco reco2

	# Print maps
	bart slice 6 0 reco2 _t1map
	bart resize -c 0 $((SAMPLES/2)) 1 $((SAMPLES/2)) _t1map t1map_$(printf "%03.0f" $i)
	rm {sens,reco,reco2,_t1map}.{cfl,hdr} 

done

bart join 6 $(ls t1map_*.cfl | sed -e 's/\.cfl//') joined_t1maps
rm t1map_*.{cfl,hdr}
