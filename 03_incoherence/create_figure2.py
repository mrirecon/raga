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
import matplotlib.pyplot as plt
import matplotlib as mpl


DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color


if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) < 6):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: plot.py <spokes> <meta data> <output> <traj 0> ... <traj N>" )
		exit()

	sysargs = sys.argv

	spokes = np.loadtxt(sysargs[1], unpack=True) # /4 for plotting

	meta_data = np.loadtxt(sysargs[2], unpack=True, dtype=object)

	filename = sysargs[3]

	traj = []

	for i in sysargs[4:]:

		print("\t", i)

		current_traj = np.real(cfl.readcfl(i)).squeeze()

		print(np.shape(current_traj))

		traj.append(current_traj)

	print(np.shape(meta_data))

	# Create colorbar

	N = np.max(meta_data[4,:])	# Max number of spokes
	cmap = plt.get_cmap('tab20c', int(N))
	print(cmap)

	# Visualization

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

	fig, ax = plt.subplots(4, len(traj), dpi=300) #figsize=(3, 3)

	choice = [	("RAGA", 1, "PI", r"$\psi_{13}^1$"), 	\
	   		("RAGA", 7, "PI", r"$\psi_{10}^7$"), 	\
			("RAGA", 7, "2PI", r"$2\psi_{10}^7$"),	\
			("EQUI", 7, "2PI", r"$\phi$") ]
	

	for x in range(0, 4):
		for j in range(0, len(traj)):


			# Find index of selected data
			data_spoke = []

			for i in range(0, np.shape(meta_data)[1]):
				if (int(spokes[j]) == int(meta_data[4,i])):
					data_spoke.append(meta_data[:,i])
			
			data_spoke = np.array(data_spoke)

			for i in range(0, np.shape(data_spoke)[0]):
				if (choice[x][0] == data_spoke[i,1]):
					if (int(choice[x][1]) == int(data_spoke[i,2])):
						if (choice[x][2] == data_spoke[i,3]):
								ind = i
			print(ind, data_spoke[ind,0])

			steps = 1

			for i in range(0, np.shape(traj[j])[2], steps):

				spoke = ax[x,j].scatter(traj[j][0,:,i,ind], traj[j][1,:,i,ind], color=cmap(i), s=1)

				if (1 == j):
					ax[x,j].text(1.15*traj[j][0,-1,i,ind], 1.15*traj[j][1,-1,i,ind], str(i), fontsize=10, horizontalalignment='center', verticalalignment='center', color=spoke.get_facecolors()[0])
				
			ax[x,j].set_xlim([-np.shape(traj[j])[1]/2, np.shape(traj[j])[1]/2])

			asp = np.diff(ax[x,j].get_xlim())[0] / np.diff(ax[x,j].get_ylim())[0]
			ax[x,j].set_aspect(asp)
			ax[x,j].axis('off')

			# SPR value
			if ((0 == x) and (0 == j)):
				ax[x,j].text(np.shape(traj[j])[1]/3, -1.1*np.shape(traj[j])[1]/2, \
		 			"SPR: "+str(np.round(np.abs(complex(data_spoke[ind,5].replace("i", "j" ))),2)), \
					fontsize=8, horizontalalignment='center', verticalalignment='center', \
					bbox=dict(facecolor=BCOLOR, edgecolor=TCOLOR, boxstyle='round'))
			else:
				ax[x,j].text(np.shape(traj[j])[1]/3, -1.1*np.shape(traj[j])[1]/2, \
		 			str(np.round(np.abs(complex(data_spoke[ind,5].replace("i", "j" ))),2)), \
					fontsize=8, horizontalalignment='center', verticalalignment='center', \
					bbox=dict(facecolor=BCOLOR, edgecolor=TCOLOR, boxstyle='round', alpha=0.6))

			if (3 == x):
				ax[x,j].text(0, -1.6*np.shape(traj[j])[1]/2, str(int(spokes[j])), fontsize=13, horizontalalignment='center', verticalalignment='center', rotation='horizontal')

			if (0 == j):
				ax[x,j].text(-1.4*np.shape(traj[j])[1]/2, 0, choice[x][3], fontsize=15, horizontalalignment='center', verticalalignment='center', rotation='vertical')

	ax[1,0].text(-2.2*np.shape(traj[j])[1]/2, 0, "RAGA Approximations", fontsize=10, horizontalalignment='center', verticalalignment='center', rotation='vertical')

	ax[3,2].text(-0.5*np.shape(traj[j])[1], -2*np.shape(traj[j])[1]/2, "Spokes", fontsize=10, horizontalalignment='center', verticalalignment='center', rotation='horizontal')

	ax[0,0].text(-2*np.shape(traj[j])[1]/2, 1.4*np.shape(traj[j])[1]/2, "B", fontsize=20, horizontalalignment='center', verticalalignment='center', rotation='horizontal', weight='bold')

	fig.subplots_adjust(right=0.8)
	cbar_ax = fig.add_axes([0.85, 0.15, 0.05, 0.7])
	norm = mpl.colors.Normalize(vmin=0, vmax=int(N))
	sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
	sm.set_array([])
	cbar = fig.colorbar(sm, cax=cbar_ax, ticks=np.linspace(0,int(N)-1,int(N)), boundaries=np.arange(-0.5,float(N)+0.5,1))
	cbar.ax.set_title('Time Indices',fontsize=10)

	fig.savefig(filename + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(filename + ".svg", bbox_inches='tight', transparent=False)
