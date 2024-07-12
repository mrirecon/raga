#!/bin/bash

set -eux

# Run Reconstruction

./run.sh


# Visualization

export DARK_LAYOUT=0

python3 create_figure.py bins.txt joined_nlinv figure


./movie/movie.sh bins.txt joined_nlinv movie

