#!/bin/bash

set -eux


# Load datasets

DATA=(
	data_res_S1597
	data_res_S0987
	data_res_S0377
	data_res_S0233
	data_res_S0089
	data_res_S0055
	data_res_S0021
	)

[ -f spokes.txt ] && rm spokes.txt
touch spokes.txt

for (( i=0; i<${#DATA[@]}; i++ ));
do

	bart copy data/"${DATA[$i]}" k

	SAMPLES=$(bart show -d 1 k)
	BR=$((SAMPLES/2))
	SPOKES=$(bart show -d 2 k)
	COILS=$(bart show -d 3 k)
	TIME=$(bart show -d 10 k)

	echo $SPOKES >> spokes.txt

	# LINEAR Trajectory with Gradient Delay correction

	bart traj -x $SAMPLES -y $SPOKES -r -D _t

	bart slice 10 0 k tmp_k

	bart traj -x $SAMPLES -y $SPOKES -r -D -O -q $(bart estdelay -R _t tmp_k) _t2
	rm tmp_k.{cfl,hdr}

	bart scale 0.5 _t2 t
	rm _t{,2}.{cfl,hdr}

	# Coil Estimation
	bart nufft -d$BR:$BR:1 -i -g -t t k psf

	bart fft -u $(bart bitmask 0 1 2) psf pattern

	bart ecalib -c 0 -m 1 pattern sens

	rm {pattern,psf}.{cfl,hdr}

	# Image Reconstruction

	bart pics -g -e -S -t t k sens tmp2
	bart flip $(bart bitmask 1) tmp2 reco_pics_$(printf "%03.0f" $i)
	rm {t,k,tmp2,sens}.{cfl,hdr}
done

bart join 5 $(ls reco_pics_*.cfl | sed -e 's/\.cfl//') joined_recos

# Estimate differences between reconstructions

bart cabs joined_recos abs
bart cabs reco_pics_000 tmp 	# Highest number of spokes as reference
bart repmat 5 "${#DATA[@]}" tmp ref
bart saxpy -- -1 ref abs diff_recos

rm reco_pics_*.{cfl,hdr}
rm {abs,tmp,ref}.{cfl,hdr}