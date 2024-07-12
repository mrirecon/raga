#!/bin/bash

set -eux

# Load data

./data/load_data.sh

# Run Reconstruction

[[ ! -f "joined_nlinv.cfl" ]] && ./binning.sh
