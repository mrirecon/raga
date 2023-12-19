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
import matplotlib.pyplot as plt

COLOR=['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8']

DARK = 0 #dark layout?
BCOLOR='white'  # Background color
TCOLOR='black'  # Text color


def gen_fib(n, ind):

	if (0 == n):
		return 1;

	if (1 == n):
		return ind

	previous, fib_number = 1, ind

	for _ in range(2, n + 1):
		previous, fib_number = fib_number, previous + fib_number

	return fib_number



if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 4):
		print( "lineplot(input)" )
		print( "#-----------------------------------------------" )
		print( "Usage: plot.py <spokes> <input> <output>" )
		exit()

	sysargs = sys.argv


	spokes = np.loadtxt(sysargs[1], unpack=True)

	label = ["GA", "GA", "GA", "RAGA", "RAGA", "RAGA", "Equi"]
	N = [1, 7, 7, 1, 7, 7, -1]
	legend = [r"$\psi^1$", r"$\psi^7$", r"$2\psi^7$", r"$\psi_{13}^1$", r"$\psi_{10}^7$", r"$2\psi_{10}^7$", "$\phi$"]

	data = np.abs(cfl.readcfl(sysargs[2])).squeeze()

	dim = np.shape(data)


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


	fig, ax = plt.subplots(dpi=300)

	for i in range(0, dim[1]-1):

		if (i < 3):
			ax.plot(spokes, data[:,i], '-', color = COLOR[i], label=label[i]+' '+legend[i], alpha=0.6)
		else:
			ax.plot(spokes, data[:,i], '.', color = COLOR[i-3], label=label[i]+' '+legend[i])

	# Reference SPR of Equidistant Traj
	ax.plot(spokes, data[:,dim[1]-1], '.', color = 'k', label=label[dim[1]-1]+' '+legend[dim[1]-1], alpha=0.6)

	ax.set_xlabel("Spokes")
	ax.set_ylabel("SPR")

	# Find and add Fib Number marks

	ymin, ymax = ax.get_ylim()
	
	c = -1 # Compensate the -1 in the list

	for inc in np.unique(N):

		max_n = 1
		while (gen_fib(max_n, inc) < np.max(spokes)):
			max_n += 1

		min_n = 1
		while (gen_fib(min_n, inc) < np.min(spokes)):
			min_n += 1

		for i in range(min_n, max_n):

			ax.axvline(x = gen_fib(i , inc), color = COLOR[c], linestyle=":", alpha=0.3)
			
			ax.text(gen_fib(i , inc), 1.01*ymax, str(gen_fib(i , inc)), horizontalalignment='center', verticalalignment='center', color = COLOR[c])

			if (max_n - 2 == i):
				ax.text(gen_fib(i , inc), (ymax+ymin)/2, "Fibonacci Element for N = "+str(inc), verticalalignment='center', rotation='vertical', alpha=0.6, color = COLOR[c])

		c += 1
	
	ax.text(-3, 1.01*ymax, "A", fontsize=20, horizontalalignment='center', verticalalignment='center', rotation='horizontal', weight='bold')

	ax.legend()

	# Add marks for increments

	
	fig.savefig(sysargs[3] + ".png", bbox_inches='tight', transparent=False)
	fig.savefig(sysargs[3] + ".svg", bbox_inches='tight', transparent=False)