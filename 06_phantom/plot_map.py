#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from mpl_toolkits.axes_grid1 import make_axes_locatable
from copy import copy

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

class plot_maps(object):

	def __init__(self, uwindow, lwindow, data, savename, colorbar_text):
		
		plt.rc('font', family='serif')

		FS = 120

		DARK = 0
		
		if "DARK_LAYOUT" in os.environ:
			DARK = int(os.environ["DARK_LAYOUT"])

		if(DARK):
			plt.style.use(['dark_background'])
		else:
			plt.style.use(['default'])

		plt.rcParams.update({
			"text.usetex": True,
			"font.family": "sans-serif",
			"font.sans-serif": "Helvetica",
		})
		
		cmap = copy(cm.get_cmap("viridis"))
		my_cmap = cm.get_cmap(cmap)
		my_cmap.set_bad('black')
		
		data = np.ma.masked_equal(data, 0)
		
		fig = plt.figure(figsize=(12, 9), dpi=80)

		#------------------------------------------------------------
		ax1 = fig.add_subplot(111)
		im = ax1.imshow(data, origin='lower', cmap=my_cmap, vmax=uwindow, vmin=lwindow)

		divider = make_axes_locatable(ax1)
		cax = divider.append_axes("right", size="5%", pad=0.05)
		cbar = plt.colorbar(im, cax=cax)
		cbar.set_label(colorbar_text, fontsize=FS+5, labelpad=40)
		cbar.ax.tick_params(labelsize=FS)

		ax1.set_yticklabels([])
		ax1.set_xticklabels([])
		ax1.xaxis.set_ticks_position('none')
		ax1.yaxis.set_ticks_position('none')
		ax1.set_axis_off()
		
		plt.tight_layout()
		
		fig.savefig(savename + ".png", bbox_inches='tight')


if __name__ == "__main__":
	#Error if wrong number of parameters
	if( len(sys.argv) != 6):
		print( "Plotting" )
		print( "#-----------------------------------------------" )
		print( "Usage: plot_map.py <upper window limit> <lower window limit>  <2D data> <savename> <colorbar text>" )
		exit()

	uwindow = float(sys.argv[1])
	lwindow = float(sys.argv[2])

	data = np.abs(cfl.readcfl(sys.argv[3]).squeeze())
	dim = np.shape(data)

	savename = sys.argv[4]
	colorbar_text = sys.argv[5]
		
	plot_maps( uwindow, lwindow, np.flip(data), savename, colorbar_text)
