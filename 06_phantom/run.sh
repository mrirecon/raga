#!/bin/bash

set -eux


# Load data

./data/load_data.sh



# Run reconstructions for resolution comparison

[ ! -f "joined_recos.cfl" ] && ./resolution.sh


# Run binning analysis
[ ! -f "joined_nlinv.cfl" ] && ./binning.sh

# Run t1 mapping analysis
[ ! -f "joined_t1maps.cfl" ] && ./t1-mapping.sh

