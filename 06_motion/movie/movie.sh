#!/bin/bash

set -euxBo pipefail

export FULL_PATH=$(realpath ${0})
export ABS_PATH=$(dirname ${FULL_PATH})


export DARK_LAYOUT=0

echo $0

export BINS=$1
export FILE=$2
OUT=$3

export TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TIME=$(bart show -d 10 $FILE)

extract_frame ()
{
	T=$1

	# Slice time
	bart slice 10 $T $FILE $TMP/slice_$(printf "%05.0f" $T)

	# Generate frame
	python3 ${ABS_PATH}/create_frame.py $BINS $TMP/slice_$(printf "%05.0f" $T) $TMP/img_$(printf "%05.0f" $T).png
}
export -f extract_frame


nice -n5 parallel --jobs 50 extract_frame ::: `seq 0 $((TIME-1))`


# Create video
ffmpeg -framerate 6 -pattern_type glob -i "$TMP/img_*.png" ${OUT}.mp4

[ -d $TMP ] && rm -rf $TMP
