#!/bin/bash

set -eux

./run.sh

# Visualization
python3 create_figure.py grog figure

# Combine nuFFT FIgure with GROG
inkscape A.svg --export-background=white --export-filename=A.pdf
inkscape B.svg --export-background=white --export-filename=B.pdf

pdflatex --shell-escape figure_combined.tex

inkscape figure_combined.pdf --export-dpi 300 --export-ignore-filters --export-background=white --export-filename=figure_combined.png


rm A.pdf B.pdf figure.png figure.pdf