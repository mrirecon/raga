#!/bin/bash

set -eu

# Requires BART version v0.8.00-483-g7874de8a1

export OMP_NUM_THREADS=2

MIN_WINDOW=5
WSTEPS=1
MAX_WINDOW=60

TRAJ=$1
OUT=$2

BR=$(bart show -d 1 $TRAJ)
SPOKES=$(bart show -d 2 $TRAJ)

export TMP_DIR=$(mktemp -d)

FILE=w.txt
[ -f $FILE ] && rm $FILE
touch $FILE


# Function estimating the SPR
calc_spr ()
{
	t=$1
	w=$2

	TDIR=$(mktemp -d)
	trap 'rm -rf "$TDIR"' EXIT
	
	bart extract 2 $t $((t+w)) traj $TDIR/tmp_traj

	bart psf $TDIR/tmp_traj $TDIR/psf

	# Calculate Sidelobe-to-Peak Ratio

	## Find Maximum of PSF
	bart mip $(bart bitmask 0 1) $TDIR/psf $TDIR/max

	## Create "One" Object
	bart ones 1 1 $TDIR/one

	## Scale "One" Object to max
	bart fmac $TDIR/max $TDIR/one $TDIR/tmp1

	## Resize "One" object to PSF dims
	bart resize -c  0 $(bart show -d 0 $TDIR/psf) \
			1 $(bart show -d 1 $TDIR/psf) \
			$TDIR/tmp1 $TDIR/tmp2

	## Subract resized "One" object from normalized PSF
	bart saxpy -- -1 $TDIR/tmp2 $TDIR/psf $TDIR/tmp3

	## Create mask to avoid sampling center maximum
	bart vec 0 1 0 1 1 1 0 1 0 $TDIR/vec
	bart reshape $(bart bitmask 0 1) 3 3 $TDIR/vec $TDIR/_mask
	bart resize -c 	0 $(bart show -d 0 $TDIR/psf) \
			1 $(bart show -d 1 $TDIR/psf) \
			$TDIR/_mask $TDIR/__mask
	bart ones 2 $(bart show -d 0 $TDIR/psf) $(bart show -d 1 $TDIR/psf) $TDIR/ones
	bart saxpy -- -1 $TDIR/__mask $TDIR/ones $TDIR/mask

	# Apply mask
	bart fmac $TDIR/mask $TDIR/tmp3 $TDIR/tmp4

	## Divide by maximum
	bart invert $TDIR/max $TDIR/inv

	bart scale -- $(bart show $TDIR/inv) $TDIR/tmp4 $TDIR/tmp5

	## Find MIP of resulting Difference -> SPR
	bart mip -a $(bart bitmask 0 1) $TDIR/tmp5 $TMP_DIR/spr_$(printf "%03.0f" $t)

	[ -d $TDIR ] && rm -rf $TDIR
}
export -f calc_spr


for w in `seq $MIN_WINDOW $WSTEPS $MAX_WINDOW`
do
	RSPOKES=$(((SPOKES/w)*w))
	MAXLIM=$((2*w)) # two times the window

	bart extract 2 0 $RSPOKES $TRAJ traj

	# Find all required t for windowing type

	t=0
	t_array=()

	while [ $((t+w)) -le $MAXLIM ]
	do 
		t_array+=($t)
		t=$((t+1))
	done


	# Run estimation

	for t2 in "${t_array[@]}"
	do
		calc_spr $t2 $w
	done
	# nice -n5 parallel --jobs 48 calc_spr ::: `echo ${t_array[@]}` ::: $w

	# Join and post-process

	bart join 0 $(ls $TMP_DIR/spr_*.cfl | sed -e 's/\.cfl//') spr_$(printf "%03.0f" $w)

	bart mip $(bart bitmask 0) spr_$(printf "%03.0f" $w) mip_$(printf "%03.0f" $w)

	bart avg $(bart bitmask 0) spr_$(printf "%03.0f" $w) avg_$(printf "%03.0f" $w)

	rm traj.{cfl,hdr}
	rm $TMP_DIR/spr_*.{cfl,hdr}

	echo $w >> $FILE
done

bart join 0 $(ls mip_*.cfl | sed -e 's/\.cfl//') ${OUT}_mip

bart join 0 $(ls avg_*.cfl | sed -e 's/\.cfl//') ${OUT}_avg

# Clean up

rm -rf $TMP_DIR
rm mip_*.{cfl,hdr}
rm avg_*.{cfl,hdr}
rm spr_*.{cfl,hdr}
