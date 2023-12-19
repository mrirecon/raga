# Rational Approximation of Golden Angles for Simple and Reproducible Radial Sampling

This repository includes the scripts to create the Figures for the publication

> #### Rational Approximation of Golden Angles for Simple and Reproducible Radial Sampling
> Scholand, N, Graf, C, Mackner, D, Holme, HCM, Uecker, M.
>
> Submitted to Magnetic Resonance in Medicine
> 
> [Preprint on ArXiv (DOI: 10.48550/arXiv.2401.02892)](https://doi.org/10.48550/arXiv.2401.02892)


## Requirements
This repository has been tested on Debian 11, but is assumed to work on other Linux-based operating systems, too.

#### Reconstruction
Pre-processing, reconstruction and post-processing is performed with the [BART toolbox](https://github.com/mrirecon/bart).
The provided scripts are compatible with [version 0.9.00](https://doi.org/10.5281/zenodo.10277939) or later.
If you experience any compatibility problems with later BART versions please contact us!

For running the reconstructions access to a GPU is recommended.
If the CPU should be used, please remove `-g` flags from all `bart pics ...`, `bart nufft ...`, and `bart rtnlinv ...` calls.

#### Runtime and Memory Mapping
The time and memory mapping in figure 4 requires the UNIX `time` tool and Nvidia GPUs with `nvidia-smi` installed.

#### Visualizations
<!-- FIXME: Update dependencies -->
The visualizations have been tested with `Python` (version 3.9.2) and require `numpy`, `copy`, `matplotlib`, `mpl_toolkits`, `sys`, `os`, `math`, `time`, `pandas`, and `cv2`. Ensure to have set a DISPLAY variable, when the results should be visualized.
The figures 3 and 5 require `pdflatex` and was tested with version 3.14159265-2.6-1.40.21 (TeX Live 2020/Debian).
Figure 5 requires the command line tool from `Inkscape` 1.2.2 (b0a8486541, 2022-12-01) and `montage` included in ImageMagick (tested on version 6.9.11-60 Q16 x86_64 2021-01-25).

#### Data
The data is hosted on [ZENODO](https://zenodo.org/) and **must be downloaded first**.

* Manual download: https://doi.org/10.5281/zenodo.10260251
* Download via script: Run the download script in the `./data` folder.
  * **All** files: `bash load-all.sh`
  * **Individual** files: `bash load.sh 10260251 <FILENAME> . `

Note: The data must be stored in the `./data` folder!


## Folders
Each folder contains a README file explaining how the figure can be reproduced.


[//]: <> (FIXME: Add Runtime!)

## Feedback
Please feel free to send us feedback about this scripts!
We would be happy to learn how to improve this and future script publications.


## License
This work is licensed under a **Creative Commons Attribution 4.0 International License**.
You should have received a copy of the license along with this
work. If not, see <https://creativecommons.org/licenses/by/4.0/>.
