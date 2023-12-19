#!/bin/bash

set -eux

./run.sh


python3 create_figure.py data.txt log_gpu_ga.log log_gpu_raga.log figure