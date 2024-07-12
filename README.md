# Rational Approximation of Golden Angles: Accelerated Reconstructions for Radial MRI

This repository includes the scripts to **create** the **Figures and Tables for** the publication

> #### Rational Approximation of Golden Angles: Accelerated Reconstructions for Radial MRI
> N. Scholand, P. Schaten, C. Graf, D. Mackner, H.C.M. Holme, M. Blumenthal, A. Mao, J. Assländer, and M. Uecker
>
> Submitted to Magnetic Resonance in Medicine
> 
> [Preprint on ArXiv (DOI: 10.48550/arXiv.2401.02892)](https://doi.org/10.48550/arXiv.2401.02892)

it provides basic comments and guidance through the workflows related to this publication.
Please find more details in the [interactive tutorial about RAGA sampling in BART on Github:mrirecon/raga-tutorial](https://github.com/mrirecon/raga-tutorial).

## Requirements
This repository has been tested on Debian 12, but is assumed to work on other Linux-based operating systems, too.
Virtual environments like a Windows Subsystem for Linux might work, but have not been tested yet.

#### Reconstruction
Preprocessing, reconstruction and postprocessing is performed with the [BART toolbox](https://github.com/mrirecon/bart).
The provided scripts are mostly compatible with [version 0.9.00](https://doi.org/10.5281/zenodo.10277939), but the GROG calibration and gridding requires at least commit `79fd4a72` or later, which will be included in the next release following version 0.9.00.
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

The visualizations require access to the BART toolbox. Therefore, either the environment variable `BART_TOOLBOX_PATH` or `TOOLBOX_PATH` needs to be set in the executing shell:
```code=bash
export TOOLBOX_PATH=<Path to BART Toolbox>
```
or
```code=bash
export BART_TOOLBOX_PATH=<Path to BART Toolbox>
```


#### Data
The data is hosted on [ZENODO](https://zenodo.org/) and **must be downloaded first**.

* Manual download: https://doi.org/10.5281/zenodo.12728657
* Download via script: Run the download script in the `./data` folder.
  * **All** files: `bash load-all.sh`
  * **Individual** files: `bash load.sh 12728657 <FILENAME> . `

Note: The data must be stored in the `./data` folder!


## Folders
Each folder contains a README file explaining how the figure can be reproduced.

## Runtime

|    CPU   |   GPU   | **Runtime** [min] |
| -------- | ------- | ------- |
| Intel Xeon Gold 6132 | NVIDIA Tesla V100 SXM2 32 GB  | ~2 h |


## License
This work is licensed under a **Creative Commons Attribution 4.0 International License**.
You should have received a copy of the license along with this
work. If not, see <https://creativecommons.org/licenses/by/4.0/>.


## Acknowledgment

The authors thank the ISMRM Reproducible Research Study Group for conducting a code review of the code ([Version 1: DOI 10.5281/zenodo.11287833](https://doi.org/10.5281/zenodo.11287833)) The scope of the code review covered only the code’s ease of download, quality of documentation, and ability to run, but did not consider scientific accuracy or code efficiency.


## Feedback
Please feel free to send us feedback about this scripts!
We would be happy to learn how to improve this and future script publications.

