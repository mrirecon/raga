#!/bin/bash

set -eux

# Estimate absolute paths

FULL_PATH=$(realpath ${0})
ABS_PATH=$(dirname ${FULL_PATH})

FILES=(
	data_res_S1597
	data_res_S0987
	data_res_S0377
	data_res_S0233
	data_res_S0089
	data_res_S0055
	data_res_S0021
	data_bin_raga
	data_bin_raga_ind
	data_bin_ga
	)

OUT=(
	data_res_S1597
	data_res_S0987
	data_res_S0377
	data_res_S0233
	data_res_S0089
	data_res_S0055
	data_res_S0021
	data_bin_raga
	data_bin_raga_ind
	data_bin_ga
	)

source ${ABS_PATH}/../../utils/data_loc.sh

for (( i=0; i<${#FILES[@]}; i++ ));
do
	if [[ ! -f "${ABS_PATH}/${OUT[$i]}.cfl" ]];
	then
		if [[ -f $DATA_LOC/${FILES[$i]}".cfl" ]];
		then
			bart copy $DATA_LOC/${FILES[$i]} ${ABS_PATH}/${OUT[$i]}
		else
			bart copy ${ABS_PATH}/../../data/${FILES[$i]} ${ABS_PATH}/${OUT[$i]}
		fi

		echo "Generated output file: ${ABS_PATH}/${OUT[$i]}.{cfl,hdr}" >&2
	fi
done
