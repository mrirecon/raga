#!/bin/bash

set -eux


DATA=(
	data_invivo_raga
	data_invivo_ga
	)

TRAJ=(
	RAGA
	GA
	)

BINS=(
	40
	30
	25
	20
	)

for i in `seq 0 $((${#DATA[@]}-1))`
do
	for b in `seq 0 $((${#BINS[@]}-1))`
	do

		bart cc -p 8 data/"${DATA[$i]}" ksp

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

		bart extract 10 $((TIME-5)) $((TIME-1)) _t tmp_t
		bart extract 10 $((TIME-5)) $((TIME-1)) __k tmp_k
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
			bart transpose 1 2 data/data_invivo_raga_ind ind
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

		REBIN=${BINS[$b]}
		BINTIME=$(($((SPOKES*TIME))/REBIN))

		bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) _t _t2
		bart extract 10 0 $((BINTIME*REBIN)) _t2 _t3

		bart reshape $(bart bitmask 2 10) $REBIN $BINTIME _t3 t
		rm _t{,2,3}.{cfl,hdr}

		bart reshape $(bart bitmask 2 10) 1 $((SPOKES*TIME)) _k _k2
		bart extract 10 0 $((BINTIME*REBIN)) _k2 _k3

		bart reshape $(bart bitmask 2 10) $REBIN $BINTIME _k3 k
		rm _k{,2,3}.{cfl,hdr}

		# -------------------------------------
		#    RT-NLINV Reconstruction
		# -------------------------------------
		# Reconstruct only first 100 frames to save time
		bart extract 10 0 80 t t2
		bart extract 10 0 80 k k2
		rm {t,k}.{cfl,hdr}

		bart rtnlinv -g -S -x $SAMPLES:$SAMPLES:1 -i 8 -t t2 k2 _reco_nlinv sens

		bart filter -m10 -l5 _reco_nlinv _reco_nlinv_median

		bart crop 0 150 _reco_nlinv_median tmp
		bart crop 1 150 tmp tmp2

		bart flip $(bart bitmask 0 1) tmp2 tmp3
		
		bart transpose 0 1 tmp3 reco_nlinv_$(printf "%03.0f" $b)

		rm {tmp{,2,3},t2,k2,sens,_reco_nlinv,_reco_nlinv_median}.{cfl,hdr}
	done

	bart join 5 $(ls reco_nlinv_*.cfl | sed -e 's/\.cfl//') _joined_nlinv_$(printf "%03.0f" $i)
	rm reco_nlinv_*.{cfl,hdr}

done

bart join 6 $(ls _joined_nlinv_*.cfl | sed -e 's/\.cfl//') joined_nlinv
rm _joined_nlinv_*.{cfl,hdr}

[ -f bins.txt ] && rm bins.txt
echo "${BINS[@]}" >> bins.txt