#!/bin/bash

set -eux

FIG=traj_plots
[ -d $FIG ] && rm -rf $FIG
mkdir $FIG

BR=200

BASE=("2PI" "PI")
METHODS=("RAGA" "GA" "EQUI")
GA_LIST=(1 7)
W_LIST=(5 8 13 15)
SPOKES=(377 419)

[ -f data.txt ] && rm data.txt
touch data.txt

[ -f spokes.txt ] && rm spokes.txt
touch spokes.txt

INDEX=0

for B in "${BASE[@]}";
do
	for METHOD in "${METHODS[@]}";
	do
		S_IND=0

		for NUM_GA in "${GA_LIST[@]}";
		do
			for W in "${W_LIST[@]}";
			do

				if [[ "$METHOD" == "RAGA" ]] ;
				then
					STR=$(printf "%02.0f" $INDEX)_${METHOD}$(printf "%02.0f" $NUM_GA)_${B}_W$(printf "%02.0f" $W)

					if [[ "$B" == "PI" ]] ;
					then
						bart traj -x $BR -y $((2*${SPOKES[$S_IND]})) -r -A -G -s $NUM_GA _t
					else
						bart traj -x $BR -y ${SPOKES[$S_IND]} --double-base -r -A -G -s $NUM_GA _t
					fi

					bart extract 2 0 $W _t t_$STR

					rm _t.{cfl,hdr}

				elif [[ "$METHOD" == "GA" ]]
				then
					STR=$(printf "%02.0f" $INDEX)_${METHOD}$(printf "%02.0f" $NUM_GA)_${B}_W$(printf "%02.0f" $W)

					if [[ "$B" == "PI" ]] ;
					then
						bart traj -x $BR -y $((2*${SPOKES[$S_IND]})) -r -G -s $NUM_GA _t
					else
						bart traj -x $BR -y ${SPOKES[$S_IND]} --double-base -r -G -s $NUM_GA _t
					fi

					bart extract 2 0 $W _t t_$STR

					rm _t.{cfl,hdr}

				elif [[ "$METHOD" == "EQUI" ]]
				then
					STR=$(printf "%02.0f" $INDEX)_${METHOD}_${B}_W$(printf "%02.0f" $W)

					if [[ "$B" == "PI" ]] ;
					then
						bart traj -x $BR -y $W -r t_$STR
					else
						bart traj -x $BR -y $W -D -r t_$STR
					fi

				else
					echo "Choose provided method!"

					exit 1
					
				fi

				bart psf t_$STR psf_$STR

				# Calculate Sidelobe-to-Peak Ratio

				## Find Maximum of PSF
				bart mip $(bart bitmask 0 1) psf_$STR max

				## Create "One" Object
				bart ones 1 1 one

				## Scale "One" Object to max
				bart fmac max one tmp1

				## Resize "One" object to PSF dims
				bart resize -c  0 $(bart show -d 0 psf_$STR) \
						1 $(bart show -d 1 psf_$STR) \
						tmp1 tmp2

				## Subract resized "One" object from normalized PSF
				bart saxpy -- -1 tmp2 psf_$STR tmp3

				## Create mask to avoid sampling center maximum
				bart vec 0 1 0 1 1 1 0 1 0 vec
				bart reshape $(bart bitmask 0 1) 3 3 vec _mask
				bart resize -c 	0 $(bart show -d 0 psf_$STR) \
						1 $(bart show -d 1 psf_$STR) \
						_mask __mask
				bart ones 2 $(bart show -d 0 psf_$STR) $(bart show -d 1 psf_$STR) ones
				bart saxpy -- -1 __mask ones mask

				# Apply mask
				bart fmac mask tmp3 tmp4


				## Divide by maximum
				bart invert max inv

				bart scale -- $(bart show inv) tmp4 tmp5

				## Find MIP of resulting Difference -> SPR
				bart mip -a $(bart bitmask 0 1) tmp5 spr_$STR

				rm {max,one,tmp1,tmp2,tmp3,tmp4,tmp5,inv}.{cfl,hdr}

				INDEX=$((INDEX+1))

				echo "$INDEX $METHOD $(printf "%02.0f" $NUM_GA) $B $(printf "%02.0f" $W) $(bart show spr_$STR)" >> data.txt

				echo "$W" >> spokes.txt
			done

			S_IND=$((S_IND+1))
		done
	done
done


# Save data


[ -d data ] && rm -rf data
mkdir data

for W in "${W_LIST[@]}";
do
	bart join 12 $(ls t_*_W$(printf "%02.0f" $W).cfl | sed -e 's/\.cfl//') data/t_join_W$(printf "%02.0f" $W)

	bart join 12 $(ls spr_*.cfl | sed -e 's/\.cfl//') data/spr_join
done

[ -d $FIG ] && rm -rf $FIG
rm {t,spr,psf}_*.{cfl,hdr}

