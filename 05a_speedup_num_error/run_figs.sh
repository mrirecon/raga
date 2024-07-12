#!/bin/bash

set -eux

./run.sh


[[ -f methods.txt ]] && rm methods.txt
touch methods.txt

echo -e "nufft \t nufft_nt" >> methods.txt

python3 create_figure.py methods.txt joined_data figure
