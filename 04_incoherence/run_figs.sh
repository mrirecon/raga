#!/bin/bash

set -eux

./run.sh


export DARK_LAYOUT=0

# Visualization of SPR
python3 create_figure.py w.txt joined_mip figure_part1

# Visualization of Trajectories
python3 create_figure2.py spokes.txt data.txt figure_part2 $(ls data/t_join_*.cfl | sed -e 's/\.cfl//')

# Visualization of SPR for single vs double angles
python3 create_figure3.py w.txt joined_mip_double_angle figure_part3


# Join Figures

## PNG
convert -append figure_part1.png figure_part2.png figure_part3.png figure.png

rm figure_part1.png figure_part2.png figure_part3.png

## SVG
pdflatex --shell-escape figure.tex

rm figure_part1.svg figure_part2.svg figure_part3.svg
