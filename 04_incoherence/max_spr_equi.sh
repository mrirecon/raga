#!/bin/bash

set -eu

# Requires BART version v0.8.00-483-g7874de8a1

export OMP_NUM_THREADS=1

MIN_WINDOW=5
WSTEPS=1
MAX_WINDOW=60

export BR=$1
OUT=$2

# Function estimating the SPR
calc_spr ()
{
	w=$1

	TDIR=$(mktemp -d)
	trap 'rm -rf "$TDIR"' EXIT

	bart traj -x $BR -y $w -D -r $TDIR/t

	bart psf $TDIR/t $TDIR/psf

	# Calculate Sidelobe-to-Peak Ratio

	## Find MIP of resulting Difference -> SPR
	bart mip $(bart bitmask 0 1) $TDIR/psf $TDIR/max

	## Create "One" Object
	bart ones 1 1 $TDIR/one

	bart fmac $TDIR/max $TDIR/one $TDIR/tmp1

	## Resize "One" object to PSF dims
	bart resize -c	0 $(bart show -d 0 $TDIR/psf) \
			1 $(bart show -d 1 $TDIR/psf) \
			$TDIR/tmp1 $TDIR/tmp2

	## Subract resized "One" object from normalized PSF
	bart saxpy -- -1 $TDIR/tmp2 $TDIR/psf $TDIR/tmp3

	# Create mask to avoid sampling center maximum
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
	bart mip -a $(bart bitmask 0 1) $TDIR/tmp5 spr_eq_$(printf "%03.0f" $w)

	[ -d $TDIR ] && rm -rf $TDIR
}
export -f calc_spr


w_array=(`seq $MIN_WINDOW $WSTEPS $MAX_WINDOW`)

for w2 in "${w_array[@]}"
do
	calc_spr $w2
done
# nice -n5 parallel --jobs 48 calc_spr ::: `echo ${w_array[@]}`

bart join 0 $(ls spr_eq_*.cfl | sed -e 's/\.cfl//') ${OUT}

rm spr_*.{cfl,hdr}