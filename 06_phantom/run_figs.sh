#!/bin/bash

set -eux



# ./run.sh


# Visualization

## A: Resolution Subfigure
python3 create_figure_A.py spokes.txt joined_recos diff_recos figure_A


## B: Binning Presentation

#### Recos

bart slice 6 0 joined_nlinv joined_raga

bart mip -a $(bart bitmask 0 1 5 10) joined_raga max

[ -d bin ] && rm -rf bin
mkdir bin

for i in `seq 0 $(($(bart show -d 5 joined_raga)-1))`;
do
	bart slice 5 $i joined_raga bin
	bart toimg -w $(bart show max) bin bin

	if [[ "$i" == "0" ]] ;
	then
		cp bin-0000.png bin/reco_bin"$((i+1))".png

	elif [[ "$i" == "2" ]]
	then
		montage bin-0000.png bin-0001.png bin-0002.png bin-0003.png -tile 4x1 -geometry +0+0 bin/reco_bin"$((i+1))".png

	elif [[ "$i" == "3" ]]
	then
		montage bin-0000.png bin-0001.png bin-0002.png bin-0003.png bin-0004.png -tile 5x1 -geometry +0+0 bin/reco_bin"$((i+1))"_1.png

		montage bin-0005.png bin-0006.png bin-0007.png bin-0008.png bin-0009.png -tile 5x1 -geometry +0+0 bin/reco_bin"$((i+1))"_2.png
	else
		montage bin-0000.png bin-0001.png bin-0002.png bin-0003.png bin-0004.png -tile 5x1 -geometry +0+0 bin/reco_bin"$((i+1))".png
	fi

	rm bin-*.png bin.{cfl,hdr}
done

rm {joined_raga,max}.{cfl,hdr}

# T1 map
bart slice 6 0 joined_t1maps t1_raga
python3 plot_map.py 2 0 t1_raga bin/t1_raga '$T_1$ / s'


inkscape binning_canvas.svg --export-dpi 300 --export-background=white --export-filename=figure_B.png

# PDF to avoid text scaling issues
inkscape binning_canvas.svg --export-text-to-path --export-background=white --export-filename=figure_B.pdf
inkscape binning_canvas.svg --export-text-to-path --export-background=white --export-filename=figure_B.eps


# For older inkscape versions, PDF export might be difficult
# inkscape binning_canvas.svg --export-dpi 300 --export-background=white --export-png=figure_B.png
# inkscape binning_canvas.svg --export-dpi 300 --export-background=white --export-pdf=figure_B.pdf


## C: GA - RAGA Comparison
python3 create_figure_C.py joined_nlinv figure_C


## Stack all subfigures vertically

#### PNG
convert -append figure_A.png figure_B.png figure_C.png figure.png

rm figure_{A,B,C}.png

#### SVG

## SVG
pdflatex --shell-escape figure.tex

rm figure_A.svg figure_C.svg
rm figure_A.pdf figure_B.pdf figure_C.pdf
rm figure_A.eps figure_B.eps figure_C.eps
