#!/usr/bin/env python3

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from mpl_toolkits.axes_grid1 import make_axes_locatable
from copy import copy

import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

FS = 15




if __name__ == "__main__":
	#Error if wrong number of parameters
	if( len(sys.argv) != 5):
		print( "Plotting" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <data> <GPU log GA> <GPU log RAGA> <savename>" )
		exit()
	
	sysargs = sys.argv

	data =  np.loadtxt(sysargs[1], unpack=True)
	log_GA = pd.read_csv(sysargs[2], sep=' ')
	log_RAGA = pd.read_csv(sysargs[3], sep=' ')

	gpu_mem_ga = np.max(log_GA.values[:,0]) / 1000 # MiB -> Gbytes
	print("GPU Memory GA: ", gpu_mem_ga, log_GA.values[0,1])

	gpu_mem_raga = np.max(log_RAGA.values[:,0]) / 1000 # MiB -> Gbytes
	print("GPU Memory RAGA: ", gpu_mem_raga, log_RAGA.values[0,1])


	plt.rc('font', family='serif')

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
	
	fig, ax = plt.subplots(dpi=300)

	methods = ['Golden\nRatio', 'RAGA', 'Golden\nRatio', 'RAGA']

	labels = ['CPU', 'GPU', 'CPU' , 'GPU']
	time = data[:,0]
	time_GPU = data[:,1]
	hwm = data[:,2] / 1000000 # kbytes -> Gbytes

	x = np.arange(len(labels))  # the label locations
	width = 0.35  # the width of the bars

	rects1 = ax.bar(x[0] - width/2, time[0], width, color="red", alpha=0.4, label='GA')
	rects2 = ax.bar(x[0] + width/2, time[1], width, color="red", label='RAGA')

	rects1 = ax.bar(x[1] - width/2, time_GPU[0], width, color="red", alpha=0.4, label='GA')
	rects2 = ax.bar(x[1] + width/2, time_GPU[1], width, color="red", label='RAGA')

	ax2 = ax.twinx()

	rects3 = ax2.bar(x[2] - width/2, hwm[0], width, color="green", alpha=0.4, label='GA')
	rects4 = ax2.bar(x[2] + width/2, hwm[1], width, color="green", label='RAGA')

	rects3 = ax2.bar(x[3] - width/2, gpu_mem_ga, width, color="green", alpha=0.4, label='GA')
	rects4 = ax2.bar(x[3] + width/2, gpu_mem_raga, width, color="green", label='RAGA')

	# x-ticks

	ax.set_xticks(x)
	ax.set_xticklabels(labels, fontsize = FS)

	for l,i in zip(ax.xaxis.get_ticklabels(),["red", "red", "green", "green"]):
		l.set_color(i)

	ax.text((x[1] - x[0]) / 2, -21, "Reconstruction Time / s", ha="center", va="center", fontsize = FS, color="red")

	ax.text((x[3] + x[2]) / 2, -21, "Maximum Memory / Gbytes", ha="center", va="center", fontsize = FS, color="green")

	# Rectangles

	rec = ax.patches
	for rect, method in zip(rec, methods):
		height = rect.get_height()
		ax.text(
			rect.get_x() + rect.get_width() / 2, 1.005*height, method, ha="center", va="bottom", fontsize = FS-2
		)

	rec2 = ax2.patches
	for rect, method in zip(rec2, methods):
		height = rect.get_height()
		ax2.text(
			rect.get_x() + rect.get_width() / 2, 1.005*height, method, ha="center", va="bottom", fontsize = FS-2
		)	
	# ax.legend()

	# y-ticks

	ax.set_ylim([0, 1.2*max(time)])
	ax.tick_params(axis='y', colors="red", labelsize=FS)
	ax.yaxis.label.set_color("red")

	ax2.set_ylim([0, 1.2*max([hwm[0], hwm[1], gpu_mem_ga, gpu_mem_raga])])
	ax2.tick_params(axis='y', colors="green", labelsize=FS)
	ax2.spines["right"].set_edgecolor("green")
	ax2.yaxis.label.set_color("green")

	plt.tight_layout()
	
	fig.savefig(sysargs[4] + ".png", bbox_inches='tight')
	fig.savefig(sysargs[4] + ".pdf", bbox_inches='tight')