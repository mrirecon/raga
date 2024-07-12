#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: nscho
"""
import sys
import os

# Check if environmental variable pointing to BART is set correctly
if "TOOLBOX_PATH" in os.environ:
	sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
elif "BART_TOOLBOX_PATH" in os.environ:
	sys.path.insert(0, os.path.join(os.environ['BART_TOOLBOX_PATH'], 'python'))
else:
	raise AttributeError( \
		"The Path to the BART toolbox is not set.\n \
		Please set the environment variable `TOOLBOX_PATH` or `BART_TOOLBOX_PATH` in your shell:\n \
		\t`export TOOLBOX_PATH=<Path to BART Toolbox>`\n \
		Example: \n \
		\t`export TOOLBOX_PATH=/home/user/bart`\n")

import cfl

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

FS = 20
LW = 6

DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color

COLOR=['C0', 'C1', 'C2', 'C3', 'C4', 'C5']

if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 4):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <bins.txt> <input data> <output>" )
		exit()

	sysargs = sys.argv

	bins = np.loadtxt(sysargs[1], unpack=True)

	# FIXME: Remove time dim here
	data_raga = np.abs(cfl.readcfl(sysargs[2])).squeeze()[:,:,:,0]
	data_ga = np.abs(cfl.readcfl(sysargs[2])).squeeze()[:,:,:,1]

	dim = np.shape(data_raga)


	if "DARK_LAYOUT" in os.environ:
		DARK = int(os.environ["DARK_LAYOUT"])

	if(DARK):
		plt.style.use(['dark_background'])
		BCOLOR='black'
		TCOLOR='white'
	else:
		plt.style.use(['default'])

	# plt.rcParams.update({
	# 	"text.usetex": True,
	# 	"font.family": "sans-serif",
	# 	"font.sans-serif": "Helvetica",
	# })

	# Visualization

	fig, ax = plt.subplots(dim[2], 2, figsize=(0.8*dim[2], 6), dpi=300)

	for i in range(0, dim[2]):

		# RAGA data

		ax[i,0].imshow(data_raga[:,:,i], cmap="gray")
		ax[i,0].set_yticklabels([])
		ax[i,0].set_xticklabels([])
		ax[i,0].xaxis.set_ticks_position('none')
		ax[i,0].yaxis.set_ticks_position('none')

		ax[i,0].set_ylabel(str(int(bins[i])),fontsize=FS-3, labelpad=-4, fontweight="bold")

		# GA data

		ax[i,1].imshow(data_ga[:,:,i], cmap="gray")
		ax[i,1].set_yticklabels([])
		ax[i,1].set_xticklabels([])
		ax[i,1].xaxis.set_ticks_position('none')
		ax[i,1].yaxis.set_ticks_position('none')

		if (0 == i):
			ax[i,0].set_title(r'RAGA $\psi_{13}^1$', color=TCOLOR, fontsize=FS-5, fontweight="bold")
			ax[i,1].set_title(r'GR $\psi^1$', color=TCOLOR, fontsize=FS-5, fontweight="bold")

	ax[0,0].text(-0.4*dim[0], dim[2]//2 * dim[1], "Spokes / Frame", horizontalalignment='center', verticalalignment='center', color=TCOLOR, rotation="vertical", fontsize=FS-5, fontweight="bold")

	plt.subplots_adjust(wspace=-0.15, hspace=0.05)

	fig.savefig(sysargs[3] + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[3] + ".pdf", bbox_inches='tight', transparent=False)
