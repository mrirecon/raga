#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import matplotlib
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

FS = 20
MS = 10

BCOLOR='white'  # Background color
TCOLOR='black'  # Text color

if __name__ == "__main__":
	#Error if wrong number of parameters
	if( len(sys.argv) != 3):
		print( "Plotting" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <data> <savename>" )
		exit()
	
	sysargs = sys.argv

	data =  np.real(cfl.readcfl(sysargs[1])).squeeze()

	print(np.shape(data))
	print((data))

	plt.rc('font', family='serif')

	DARK = 0
	
	if "DARK_LAYOUT" in os.environ:
		DARK = int(os.environ["DARK_LAYOUT"])

	if(DARK):
		plt.style.use(['dark_background'])
		BCOLOR='black'
		TCOLOR='white'
	else:
		plt.style.use(['default'])

	plt.rcParams.update({
		# "text.usetex": True,
		# "font.family": "sans-serif",
		# "font.sans-serif": "Helvetica",
	})
	
	data = np.ma.masked_equal(data, 0)
	
	fig, ax = plt.subplots(1, 1, dpi=300, sharex=True)

	methods = ['Golden\nRatio', 'RAGA', 'Golden\nRatio', 'RAGA']

	labels = ['Calibration\nTime / s', 'Gridding\nTime / s']

	# Extract Timings
	tcal = np.vstack((data[0,:], data[2,:]))
	tgrid = np.vstack((data[1,:], data[3,:]))

	# Create Rectangles of Visualization

	x = np.arange(len(labels))  # the label locations
	width = 0.35  # the width of the bars

	rects1 =ax.bar(x[0] - width/2, np.mean(tcal[0,:]), width, color="orange", alpha=0.4)
	ax.errorbar(x[0] - width/2, np.mean(tcal[0,:]), yerr=np.std(tcal[0,:]), color=TCOLOR, fmt='.', markersize=MS, label='Std of '+str(int(np.shape(tcal)[1]))+' Runs')

	rects2 =ax.bar(x[0] + width/2, np.mean(tcal[1,:]), width, color="orange")
	ax.errorbar(x[0] + width/2, np.mean(tcal[1,:]), yerr=np.std(tcal[1,:]), color=TCOLOR, fmt='.', markersize=MS)

	ax2 =ax.twinx()
	ax3 =ax.twinx()

	rects1 =ax2.bar(x[1] - width/2, np.mean(tgrid[0,:]), width, color="steelblue")
	ax2.errorbar(x[1] - width/2, np.mean(tgrid[0,:]), yerr=np.std(tgrid[0,:]), color=TCOLOR, fmt='.', markersize=MS)

	rects2 =ax3.bar(x[1] + width/2, np.mean(tgrid[1,:]), width, color="blue")
	ax3.errorbar(x[1] + width/2, np.mean(tgrid[1,:]), yerr=np.std(tgrid[1,:]), color=TCOLOR, fmt='.', markersize=MS)

	# x-ticks

	ax.set_xticks(x)
	ax.set_xticklabels(labels, fontsize = FS)

	for l,i in zip(ax.xaxis.get_ticklabels(),["orange", "blue"]):
		l.set_color(i)

	# Rectangles

	rec =ax.patches
	for rect, method in zip(rec, methods):
		height = rect.get_height()
		ax.text(
			rect.get_x() + rect.get_width() / 2, 1.01*height, method, ha="center", va="bottom", fontsize = FS-5
		)

	rec =ax2.patches
	for rect, method in zip(rec, methods):
		height = rect.get_height()
		ax2.text(
			rect.get_x() + rect.get_width() / 2, 1.01*height, "Golden\nRatio", ha="center", va="bottom", fontsize = FS-5
		)

	rec =ax3.patches
	for rect, method in zip(rec, methods):
		height = rect.get_height()
		ax3.text(
			rect.get_x() + rect.get_width() / 2, 1.01*height, "RAGA", ha="center", va="bottom", fontsize = FS-5
		)

	ax.legend(fancybox=True, framealpha=0.5, fontsize=FS-6, loc='upper left')

	# y-ticks

	ax.set_ylim([0, 0.4]) #1.2*max(tcal)])
	ax.tick_params(axis='y', colors="orange", labelsize=FS)
	ax.yaxis.label.set_color("orange")

	ax2.set_ylim([0, 70]) #1.2*max(tcal)])
	ax2.tick_params(axis='y', colors="steelblue", labelsize=FS)
	ax2.yaxis.label.set_color("blue")

	ax3.set_ylim([0, 7]) #1.2*max(tcal)])
	ax3.tick_params(axis='y', colors="blue",labelsize=FS)
	ax3.yaxis.label.set_color("blue")

	ax3.spines["right"].set_position(("axes", 1.15))

	ax.set_title("GROG", fontsize=FS)

	plt.tight_layout()
	
	fig.savefig(sysargs[2] + ".png", bbox_inches='tight')
	fig.savefig(sysargs[2] + ".pdf", bbox_inches='tight')