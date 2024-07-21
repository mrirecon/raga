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
from mpl_toolkits.axes_grid1 import make_axes_locatable

import matplotlib.patches as mpatches

FS = 30
LW = 4

VMIN = 0
VMAX = 1

DIFF_SCALING = 20

DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color

COLOR=['C0', 'C1', 'C2', 'C3', 'C4', 'C5']

if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 3):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <input data> <output>" )
		exit()

	sysargs = sys.argv

	data = np.abs(cfl.readcfl(sysargs[1])).squeeze()

	dim = np.shape(data)

	print(dim)

	max_value = np.max(data)


	if "DARK_LAYOUT" in os.environ:
		DARK = int(os.environ["DARK_LAYOUT"])

	if(DARK):
		plt.style.use(['dark_background'])
		BCOLOR='black'
		TCOLOR='white'
	else:
		plt.style.use(['default'])

	plt.rcParams.update({
		"text.usetex": True,
		"font.family": "sans-serif",
		"font.sans-serif": "Helvetica",
	})

	scale = 1 / max_value
	bins = 2

	# Visualization

	fig, ax = plt.subplots(3, 5, figsize=(3*5, 3*3), dpi=300)

	for i in range(0, 5):

		# Reconstructions RAGA

		im1 = ax[0,i].imshow(data[:,:,bins,0,i] * scale , cmap="gray", vmin=VMIN, vmax=VMAX)

		ax[0,i].set_yticklabels([])
		ax[0,i].set_xticklabels([])
		ax[0,i].xaxis.set_ticks_position('none')
		ax[0,i].yaxis.set_ticks_position('none')


		# Reconstructions GA

		im1 = ax[1,i].imshow(data[:,:,bins,1,i] * scale , cmap="gray", vmin=VMIN, vmax=VMAX)

		ax[1,i].set_yticklabels([])
		ax[1,i].set_xticklabels([])
		ax[1,i].xaxis.set_ticks_position('none')
		ax[1,i].yaxis.set_ticks_position('none')


		# Difference |RAGA - GA|

		diff = np.abs(data[:,:,bins,0,i] - data[:,:,bins,1,i])

		# Top: Same scaling as images
		joined = diff[:,:] * scale

		# Bottom: normalized to 1
		joined[dim[1]//2:,:] = diff[dim[1]//2:,:] * scale * DIFF_SCALING

		im2 = ax[2,i].imshow(joined, cmap="gray", vmin=VMIN, vmax=VMAX)

		ax[2,i].text(0.99*dim[0], 0.99*dim[1], "x"+str(int(DIFF_SCALING)), horizontalalignment='right', verticalalignment='bottom', color=TCOLOR, rotation="horizontal", fontsize=FS-5, fontweight="bold")
		

		ax[2,i].set_yticklabels([])
		ax[2,i].set_xticklabels([])
		ax[2,i].xaxis.set_ticks_position('none')
		ax[2,i].yaxis.set_ticks_position('none')

		ax[0,i].set_title(str(int(i*55))+"-"+str(int((i+1)*55)), fontsize=FS)

		if (0 == i):

			ax[0,i].text(0.99*dim[0] + 5//2 * dim[0], -0.2*dim[1], "Spokes after Inversion", horizontalalignment='center', verticalalignment='bottom', color=TCOLOR, rotation="horizontal", fontsize=FS+5, fontweight="bold")

			ax[0,i].set_ylabel(r"RAGA", fontsize=FS)
			ax[1,i].set_ylabel(r"GA", fontsize=FS)
			ax[2,i].set_ylabel(r"abs(RAGA-GA)", fontsize=FS-3)

	fig.subplots_adjust(right=0.95)
	cbar_ax = fig.add_axes([0.96, 0.125, 0.01, 0.75])
	norm = mpl.colors.Normalize(vmin=VMIN, vmax=VMAX)
	sm = plt.cm.ScalarMappable(cmap="gray", norm=norm)
	sm.set_array([])
	cbar = fig.colorbar(sm, cax=cbar_ax)
	cbar.ax.tick_params(labelsize=FS)

	ax[0,0].text(-0.2* dim[0], -0.2*dim[1], "C", fontsize=FS+10, horizontalalignment='center', verticalalignment='center', rotation='horizontal', weight='bold', color=TCOLOR)

	plt.subplots_adjust(wspace=0.02, hspace=0.05)

	fig.savefig(sysargs[2] + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[2] + ".svg", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[2] + ".eps", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[2] + ".pdf", bbox_inches='tight', transparent=False)
