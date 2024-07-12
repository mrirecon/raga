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

import cv2

FS = 35
LW = 6

DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color

COLOR=['C0', 'C1', 'C2', 'C3', 'C4', 'C5']

TR = 2.9 # ms

def lin_interpol(values, data):

	floor = np.floor(values)
	fdiff = np.abs(values - floor)

	ceil = np.ceil(values)
	cdiff = np.abs(values - ceil)

	adiff = np.abs(floor - ceil)

	linedata = []

	newdim = np.shape(data)

	for f in range(0, newdim[2]):

		line_single = []

		for i in range(0, samples):

			frame = data[:,:,f].T
			
			ref1 = frame[int(floor[0,i]),int(floor[1,i])]
			ref2 = frame[int(floor[0,i]),int(ceil[1,i])]
			ref3 = frame[int(ceil[0,i]),int(floor[1,i])]
			ref4 = frame[int(ceil[0,i]),int(ceil[1,i])]

			scale = 1

			if ( (0 != adiff[0,i]) and (0 != adiff[1,i]) ):
				scale = 1 / (adiff[0,i] * adiff[1,i])

			result = scale \
				* ( ref1 * cdiff[0,i] * cdiff[1,i] \
				+ ref2 * cdiff[0,i] * fdiff[1,i] \
				+ ref3 * fdiff[0,i] * cdiff[1,i] \
				+ ref4 * fdiff[0,i] * fdiff[1,i] )

			line_single.append(result)

		linedata.append(line_single)
	
	linedata = np.flip(np.array(linedata).T, axis=0)

	return linedata

if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 4):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <bins.txt> <input data> <output>" )
		exit()

	sysargs = sys.argv

	bins = np.loadtxt(sysargs[1], unpack=True)

	data_raga = np.abs(cfl.readcfl(sysargs[2])).squeeze()[:,:,:,0,:]
	data_ga = np.abs(cfl.readcfl(sysargs[2])).squeeze()[:,:,:,1,:]

	dim = np.shape(data_raga)


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

	dia_raga = [10, 15, 8, 12]
	dia_ga = [11, 15, 8, 12]

	# Visualization

	fig, ax = plt.subplots(dim[2], 4, figsize=(3*dim[2], 12), dpi=300)

	for i in range(0, dim[2]):

		# Define line
		s = [32, 112]
		e = [103, 22]


		ax[i,0].imshow(data_raga[:,:,i,dia_raga[i]], cmap="gray")
		ax[i,0].set_yticklabels([])
		ax[i,0].set_xticklabels([])
		ax[i,0].xaxis.set_ticks_position('none')
		ax[i,0].yaxis.set_ticks_position('none')

		# Plot line
		if (dim[2]-1 == i):
			ax[i,0].plot([s[0], e[0]], [s[1], e[1]], ':', linewidth=LW, color=COLOR[1])



		# Find coordinates of sampling points
		vis_spokes = 1800
		samples = 90 # for squared image
		tend = int(vis_spokes / bins[i])

		p = np.linspace(0, samples, samples)

		x = s[0] + (e[0] - s[0]) / samples * p
		y = s[1] + (e[1] - s[1]) / samples * p

		values = np.array([x, y])


		# Linear Interpolation

		linedata = lin_interpol(values, data_raga[:,:,i,:])

		evo_dim = np.shape(linedata)
		ax[i,1].imshow(cv2.resize(linedata[:,0:tend], (dim[3], samples), cv2.INTER_LINEAR), cmap="gray")

		if (dim[2]-1 == i):
			ax[i,1].plot([dia_raga[i], dia_raga[i]], [0, np.shape(linedata)[0]-1], ":", linewidth=LW, color=COLOR[1])

		ax[i,1].set_yticklabels([])
		ax[i,1].yaxis.set_ticks_position('none')

		# GA data

		ax[i,2].imshow(data_ga[:,:,i, dia_ga[i]], cmap="gray")
		ax[i,2].set_yticklabels([])
		ax[i,2].set_xticklabels([])
		ax[i,2].xaxis.set_ticks_position('none')
		ax[i,2].yaxis.set_ticks_position('none')
		
		if (dim[2]-1 == i):
			ax[i,2].plot([s[0], e[0]], [s[1], e[1]], ':', linewidth=LW, color=COLOR[2])


		linedata2 = lin_interpol(values, data_ga[:,:,i,:])
		ax[i,3].imshow(cv2.resize(linedata2[:,0:tend], (dim[3], samples), cv2.INTER_LINEAR), cmap="gray")

		if (dim[2]-1 == i):
			ax[i,3].plot([dia_ga[i], dia_ga[i]], [0, np.shape(linedata2)[0]-1], ":", linewidth=LW, color=COLOR[2])

		ax[i,3].set_yticklabels([])
		ax[i,3].yaxis.set_ticks_position('none')
		
		if (0 == i):
			ax[i,0].set_ylabel(str(int(bins[i])),fontsize=FS, fontweight="bold")
		else:
			ax[i,0].set_ylabel(str(int(bins[i])),fontsize=FS, fontweight="bold")		

		if (dim[2]-1 == i):

			def scaleFormatter(x, pos):
				return "{0:.2f}%".format((x * bins[i] * TR)/1000)

			ax[i,1].xaxis.set_major_formatter(mpl.ticker.FuncFormatter(scaleFormatter))
			ax[i,1].xaxis.set_major_locator(plt.MaxNLocator(3))
			ax[i,1].tick_params(axis="x", labelsize=FS-12)
			ax[i,1].set_xlabel(r"time / s",fontsize=FS-5, fontweight="bold")

			ax[i,3].xaxis.set_major_formatter(mpl.ticker.FuncFormatter(scaleFormatter))
			ax[i,3].xaxis.set_major_locator(plt.MaxNLocator(3))
			ax[i,3].tick_params(axis="x", labelsize=FS-12)
			ax[i,3].set_xlabel(r"time / s",fontsize=FS-5, fontweight="bold")

		else:
			ax[i,1].set_xticklabels([])
			ax[i,1].xaxis.set_ticks_position('none')

			ax[i,3].set_xticklabels([])
			ax[i,3].xaxis.set_ticks_position('none')


	ax[0,0].text(-0.4*dim[0], dim[2]//2 * dim[1], "Spokes / Frame", horizontalalignment='center', verticalalignment='center', color=TCOLOR, rotation="vertical", fontsize=FS, fontweight="bold")

	ax[0,0].text(1.1*dim[0], -0.17*dim[1], r'RAGA $\psi_{13}^1$', horizontalalignment='center', verticalalignment='center', color=TCOLOR, rotation="horizontal", fontsize=FS+2, fontweight="bold")

	ax[0,2].text(1.1*dim[0], -0.17*dim[1], r'Golden Ratio $\psi^1$', horizontalalignment='center', verticalalignment='center', color=TCOLOR, rotation="horizontal", fontsize=FS+2, fontweight="bold")

	plt.subplots_adjust(wspace=-0.15, hspace=0.05)

	fig.savefig(sysargs[3] + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[3] + ".pdf", bbox_inches='tight', transparent=False)