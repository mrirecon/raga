#!/usr/bin/env python3

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from mpl_toolkits.axes_grid1 import make_axes_locatable
from copy import copy
import glob

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

FS = 13




if __name__ == "__main__":
	#Error if wrong number of parameters
	if( len(sys.argv) != 4):
		print( "Plotting" )
		print( "#-----------------------------------------------" )
		print( "Usage: create_figure.py <methods> <data> <savename>" )
		exit()
	
	sysargs = sys.argv

	reco_tech =  np.loadtxt(sysargs[1], dtype=str, unpack=True)

	print(reco_tech[0])

	data =  np.real(cfl.readcfl(sysargs[2])).squeeze()

	print(np.shape(data))
	print((data))


	plt.rc('font', family='serif')

	DARK = 0
	
	if "DARK_LAYOUT" in os.environ:
		DARK = int(os.environ["DARK_LAYOUT"])

	if(DARK):
		plt.style.use(['dark_background'])
	else:
		plt.style.use(['default'])

	plt.rcParams.update({
		# "text.usetex": True,
		# "font.family": "sans-serif",
		# "font.sans-serif": "Helvetica",
	})
	
	cmap = copy(cm.get_cmap("viridis"))
	my_cmap = cm.get_cmap(cmap)
	my_cmap.set_bad('black')
	
	data = np.ma.masked_equal(data, 0)
	
	fig, ax = plt.subplots(2, 1, dpi=300, sharex=True)

	methods = ['Golden\nRatio', 'RAGA', 'Golden\nRatio', 'RAGA']

	labels = ['CPU', 'GPU', 'CPU' , 'GPU']

	titles = ['with Toeplitz', 'without Toeplitz']

	for ii in range(0, np.shape(data)[1]):

		print("Reconstruction Method: " + reco_tech[ii])

		# xc = ii // 2
		# yc = ii % 2

		# Extract Timings and HWM
		time = data[0:2,ii,:]
		time_GPU = data[2:4,ii,:]
		hwm = data[4:6,ii,:] / 1000000 # kbytes -> Gbytes

		# Extract GPU data usage from nvidia-smi log files

		## Find all log files of the individual runs
		gpu_mem_ga = []

		for file in glob.glob("log/log_gpu_ga_" + reco_tech[ii] + "_run_*.log"):

			log_GA = pd.read_csv(file, sep=' ')

			gpu_mem_ga_tmp = np.max(log_GA.values[:,0]) / 1000 # MiB -> Gbytes
			print("GPU Memory GA: ", gpu_mem_ga_tmp, log_GA.values[0,1], file)

			gpu_mem_ga.append(gpu_mem_ga_tmp)


		gpu_mem_raga = []

		for file in glob.glob("log/log_gpu_raga_" + reco_tech[ii] + "_run_*.log"):

			log_RAGA = pd.read_csv(file, sep=' ')

			gpu_mem_raga_tmp = np.max(log_RAGA.values[:,0]) / 1000 # MiB -> Gbytes
			print("GPU Memory RAGA: ", gpu_mem_raga_tmp, log_RAGA.values[0,1], file)

			gpu_mem_raga.append(gpu_mem_raga_tmp)

		## Calculate Statistics
		gpu_mem_ga_mean = np.mean(gpu_mem_ga)
		gpu_mem_ga_std = np.std(gpu_mem_ga)

		print("Mean GA GPU Memory: ", gpu_mem_ga_mean, "+-", gpu_mem_ga_std, "GB")

		gpu_mem_raga_mean = np.mean(gpu_mem_raga)
		gpu_mem_raga_std = np.std(gpu_mem_raga)

		print("Mean RAGA GPU Memory: ", gpu_mem_raga_mean, "+-", gpu_mem_raga_std, "GB")

		# Create Rectangles of Visualization

		x = np.arange(len(labels))  # the label locations
		width = 0.35  # the width of the bars

		rects1 =ax[ii].bar(x[0] - width/2, np.mean(time[0,:]), width, color="red", alpha=0.4)
		ax[ii].errorbar(x[0] - width/2, np.mean(time[0,:]), yerr=np.std(time[0,:]), color="k", fmt='.', label='Std of '+str(int(np.shape(time)[1]))+' Runs')

		rects2 =ax[ii].bar(x[0] + width/2, np.mean(time[1,:]), width, color="red")
		ax[ii].errorbar(x[0] + width/2, np.mean(time[1,:]), yerr=np.std(time[1,:]), color="k", fmt='.')

		rects1 =ax[ii].bar(x[1] - width/2, np.mean(time_GPU[0,:]), width, color="red", alpha=0.4,)
		ax[ii].errorbar(x[1] - width/2, np.mean(time_GPU[0,:]), yerr=np.std(time_GPU[0,:]), color="k", fmt='.')

		rects2 =ax[ii].bar(x[1] + width/2, np.mean(time_GPU[1,:]), width, color="red")
		ax[ii].errorbar(x[1] + width/2, np.mean(time_GPU[1,:]), yerr=np.std(time_GPU[1,:]), color="k", fmt='.')

		ax2 =ax[ii].twinx()

		rects3 = ax2.bar(x[2] - width/2, np.mean(hwm[0,:]), width, color="green", alpha=0.4)
		ax2.errorbar(x[2] - width/2, np.mean(hwm[0,:]), yerr=np.std(hwm[0,:]), color="k", fmt='.')

		rects4 = ax2.bar(x[2] + width/2, np.mean(hwm[1,:]), width, color="green", label='RAGA')
		ax2.errorbar(x[2] + width/2, np.mean(hwm[1,:]), yerr=np.std(hwm[1,:]), color="k", fmt='.')

		rects3 = ax2.bar(x[3] - width/2, gpu_mem_ga_mean, width, color="green", alpha=0.4)
		ax2.errorbar(x[3] - width/2, gpu_mem_ga_mean, yerr=gpu_mem_ga_std, color="k", fmt='.')

		rects4 = ax2.bar(x[3] + width/2, gpu_mem_raga_mean, width, color="green", label='RAGA')
		ax2.errorbar(x[3] + width/2, gpu_mem_raga_mean, yerr=gpu_mem_raga_std, color="k", fmt='.')

		# x-ticks

		ax[ii].set_xticks(x)
		ax[ii].set_xticklabels(labels, fontsize = FS)

		for l,i in zip(ax[ii].xaxis.get_ticklabels(),["red", "red", "green", "green"]):
			l.set_color(i)

		# Rectangles

		if (0 == ii):
			rec =ax[ii].patches
			for rect, method in zip(rec, methods):
				height = rect.get_height()
				ax[ii].text(
					rect.get_x() + rect.get_width() / 2, 1.005*height, method, ha="center", va="bottom", fontsize = FS-2
				)

			rec2 = ax2.patches
			for rect, method in zip(rec2, methods):
				height = rect.get_height()
				ax2.text(
					rect.get_x() + rect.get_width() / 2, 1.005*height, method, ha="center", va="bottom", fontsize = FS-2
				)

			ax[ii].set_title('nuFFT Reconstruction', color='k', fontsize=FS)

		if (1 == ii):
			ax[ii].text((x[1] - x[0]) / 2, -41, "Reconstruction Time / s", ha="center", va="center", fontsize = FS, color="red")

			ax[ii].text((x[3] + x[2]) / 2, -41, "Maximum Memory / Gbytes", ha="center", va="center", fontsize = FS, color="green")

			ax[ii].legend(fancybox=True, framealpha=0.5, loc='upper left')

		# y-ticks

		print(time)

		ax[ii].set_ylim([0, 200]) #1.2*max(time)])
		ax[ii].tick_params(axis='y', colors="red", labelsize=FS)
		ax[ii].yaxis.label.set_color("red")

		# ax[ii].text(0.9, 0.9*1.2*max([hwm[0], hwm[1], gpu_mem_ga_mean, gpu_mem_raga_mean]), reco_tech[ii], fontsize = FS, ha="right", va="top", bbox=dict(boxstyle="round,pad=0.1", facecolor='white', alpha=0.95))

		ax[ii].set_ylabel(titles[ii], color='k', fontsize=FS)

		ax2.set_ylim([0, 12]) #1.2*max([hwm[0], hwm[1], gpu_mem_ga_mean, gpu_mem_raga_mean])])
		ax2.tick_params(axis='y', colors="green", labelsize=FS)
		ax2.spines["right"].set_edgecolor("green")
		ax2.yaxis.label.set_color("green")

	plt.tight_layout()
	
	fig.savefig(sysargs[3] + ".png", bbox_inches='tight')
	fig.savefig(sysargs[3] + ".pdf", bbox_inches='tight')