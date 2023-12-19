#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: nscho
"""
import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable

FS = 30
LW = 4

VMIN = 0
VMAX = 1

DIFF_SCALE=10

DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color

COLOR=['C0', 'C1', 'C2', 'C3', 'C4', 'C5']

if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 5):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <spokes.txt> <input data> <input diff> <output>" )
		exit()

	sysargs = sys.argv

	spokes = np.loadtxt(sysargs[1], unpack=True)

	data = np.abs(cfl.readcfl(sysargs[2])).squeeze()
	diff = np.abs(cfl.readcfl(sysargs[3])).squeeze()

	dim = np.shape(data)

	print(dim)
	print(np.shape(diff))

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

	# Visualization

	fig, ax = plt.subplots(2, dim[2], figsize=(14, 4), dpi=300)

	for i in range(0, dim[2]):

		# Reconstructions

		im1 = ax[0,i].imshow(data[:,:,i] * scale , cmap="gray", vmin=VMIN, vmax=VMAX)

		ax[0,i].set_yticklabels([])
		ax[0,i].set_xticklabels([])
		ax[0,i].xaxis.set_ticks_position('none')
		ax[0,i].yaxis.set_ticks_position('none')

		# Differences
		
		if (0 == i):
		
			ax[1,i].set_visible(False)

			ax[0,i].text(0.99*dim[0], 0.99*dim[1], "Ref", horizontalalignment='right', verticalalignment='bottom', color=BCOLOR, rotation="horizontal", fontsize=FS-5, fontweight="bold")

		else:

			# Top: Same scaling as images
			joined = diff[:,:,i] * scale

			# Bottom: normalized to 1
			joined[dim[1]//2:,:] = diff[dim[1]//2:,:,i] * scale * DIFF_SCALE

			im2 = ax[1,i].imshow(joined, cmap="gray", vmin=VMIN, vmax=VMAX)

			ax[1,i].text(0.99*dim[0], 0.99*dim[1], "x"+str(int(DIFF_SCALE)), horizontalalignment='right', verticalalignment='bottom', color=BCOLOR, rotation="horizontal", fontsize=FS-5, fontweight="bold")
			

			ax[1,i].set_yticklabels([])
			ax[1,i].set_xticklabels([])
			ax[1,i].xaxis.set_ticks_position('none')
			ax[1,i].yaxis.set_ticks_position('none')

		
		ax[0,i].set_title(str(int(spokes[i])), fontsize=FS)

		if (1 == i):

			ax[1,i].set_ylabel(r"$|$Ref - Img$|$", fontsize=FS-3)

			ax[0,i].text(0.99*dim[0], 0.99*dim[1], "Img", horizontalalignment='right', verticalalignment='bottom', color=BCOLOR, rotation="horizontal", fontsize=FS-5, fontweight="bold")

	# Title
	ax[0,0].text(0.99*dim[0] + dim[2]//2 * dim[0], -0.3*dim[1], "Spokes/Frame", horizontalalignment='center', verticalalignment='bottom', color=TCOLOR, rotation="horizontal", fontsize=FS, fontweight="bold")

	# Colorbar

	fig.subplots_adjust(right=0.95)
	cbar_ax = fig.add_axes([0.96, 0.125, 0.01, 0.75])
	norm = mpl.colors.Normalize(vmin=VMIN, vmax=VMAX)
	sm = plt.cm.ScalarMappable(cmap="gray", norm=norm)
	sm.set_array([])
	cbar = fig.colorbar(sm, cax=cbar_ax)
	cbar.ax.tick_params(labelsize=FS-5)

	# Mark Nyquist

	x,y = np.array([[1.05*dim[0], 1.05*dim[0]], [-0.1*dim[1],2.1 * dim[1]]])
	line = mpl.lines.Line2D(x, y, lw=5., color='r')
	line.set_clip_on(False)
	ax[0,1].add_line(line)

	ax[1,1].text(1.05*dim[0], 1.2*dim[1], r"$\leftarrow$ Nyquist Limit", fontsize=FS-5, horizontalalignment='center', verticalalignment='center', rotation='horizontal', weight='bold', color='red')


	# Letter

	ax[0,0].text(-0.4* dim[0], -0.3*dim[1], "A", fontsize=FS+10, horizontalalignment='center', verticalalignment='center', rotation='horizontal', weight='bold')

	plt.subplots_adjust(wspace=0.05, hspace=0.05)

	fig.savefig(sysargs[4] + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[4] + ".svg", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[4] + ".eps", bbox_inches='tight', transparent=False)