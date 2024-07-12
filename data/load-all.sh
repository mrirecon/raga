#!/bin/bash

set -B

# DOI: 10.5281/zenodo.12728657
ZENODO_RECORD=12728657

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
	data_invivo_ga
	data_invivo_raga
	data_invivo_raga_ind
	)

for i in  "${FILES[@]}";
do
	./load-cfl.sh ${ZENODO_RECORD} ${i} .
done
