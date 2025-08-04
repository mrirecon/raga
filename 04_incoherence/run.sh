#!/bin/bash

set -eux

export BART_COMPAT_VERSION=v0.9.00

BR=200


# GA 1 Trajectory
if [ ! -f "ga01_mip.hdr" ]
then
	NUM_GA=1
	SPOKES=377
	bart traj -x $BR -y $((2*SPOKES)) -r -G -s $NUM_GA t
	./estim_max_spr.sh t ga01 r
	rm t.{cfl,hdr}
fi

# GA 7 Trajectory
if [ ! -f "ga07_mip.hdr" ]
then
	NUM_GA=7
	SPOKES=419
	bart traj -x $BR -y $((2*SPOKES)) -r -G -s $NUM_GA t
	./estim_max_spr.sh t ga07
	rm t.{cfl,hdr}
fi

# GA 7 Trajectory Double Base
if [ ! -f "ga07_2Pi_mip.hdr" ]
then
	NUM_GA=7
	SPOKES=419
	bart traj -x $BR -y $SPOKES --double-base -r -G -s $NUM_GA t
	./estim_max_spr.sh t ga07_2Pi
	rm t.{cfl,hdr}
fi


# RAGA 1 Trajectory
if [ ! -f "raga01_mip.hdr" ]
then
	NUM_GA=1
	SPOKES=377
	bart traj -x $BR -y $((2*SPOKES)) -A -r -G -s $NUM_GA t
	./estim_max_spr.sh t raga01
	rm t.{cfl,hdr}
fi


# RAGA 7 Trajectory
if [ ! -f "raga07_mip.hdr" ]
then
	NUM_GA=7
	SPOKES=419
	bart traj -x $BR -y $((2*SPOKES)) -A -r -G -s $NUM_GA t
	./estim_max_spr.sh t raga07
	rm t.{cfl,hdr}
fi


# RAGA 7 Trajectory
if [ ! -f "raga07_2Pi_mip.hdr" ]
then
	NUM_GA=7
	SPOKES=419
	bart traj -x $BR -y $SPOKES --double-base -A -r -G -s $NUM_GA t
	./estim_max_spr.sh t raga07_2Pi
	rm t.{cfl,hdr}
fi


# Equidistant Baseline
if [ ! -f "equi_dist.hdr" ]
then
	./max_spr_equi.sh $BR equi_dist
fi

bart join 1 ga01_mip ga07_mip ga07_2Pi_mip raga01_mip raga07_mip raga07_2Pi_mip equi_dist joined_mip


# Create Trajectories

./create_traj.sh


# Single vs Double Golden Ratio Angle Analsyis


# RAGA 1 Trajectory
if [ ! -f "ga02_2PI_mip.hdr" ]
then
	NUM_GA=2
	SPOKES=377
	bart traj -x $BR -y $SPOKES --double-base -r -G -s $NUM_GA t
	./estim_max_spr.sh t ga02_2PI
	rm t.{cfl,hdr}
fi


# RAGA 7 Trajectory
if [ ! -f "ga14_2PI_mip.hdr" ]
then
	NUM_GA=14
	SPOKES=419
	bart traj -x $BR -y $SPOKES --double-base -r -G -s $NUM_GA t
	./estim_max_spr.sh t ga14_2PI
	rm t.{cfl,hdr}
fi


bart join 1 ga01_mip ga07_mip ga02_2PI_mip ga14_2PI_mip joined_mip_double_angle
