#Computational Testing for Automated Preprocessing (CTAP)#

## What is CTAP? ##
The main aim of the *Computational Testing for Automated Preprocessing (CTAP)* toolbox is to provide:

1. batch processing using EEGLAB functions and
2. testing and comparison of automated methodologies.

The CTAP toolbox provides two main functionalities to achieve these aims:

1. the **core** supports scripted specification of an EEGLAB analysis pipeline and tools for running the pipe, making the workflow transparent and easy to control. Automated output of ‘quality control’ logs and imagery helps to keep track of what's going on.
2. the **testing module** uses synthetic data to generate ground truth controlled tests of preprocessing methods, with capability to generate new synthetic data matching the parameters of the lab’s own data. This allows experimenters to select the best methods for their purpose, or developers to flexibly test and benchmark their novel methods.

_If you use CTAP for your research, __please use the following citation___:
 * Cowley, B., Korpela, J., & Torniainen, J. E. (2017). Computational Testing for Automated Preprocessing: a Matlab toolbox to enable large scale electroencephalography data processing. PeerJ Computer Science, 3:e108. http://doi.org/10.7717/peerj-cs.108

## Installation ##
Clone the GitHub repository to your machine using

    git clone https://github.com/bwrc/ctap.git <destination dir>

Add the whole directory to your Matlab path. You also need to have EEGLAB added to your Matlab path.

## Getting started ##
A minimalistic working example can be found in `~/ctap/templates/minimalistic_example/`.

Copy the `cfg_minimal.m` and `runctap_minimal.m` files and use them as a starting point for your own pipe. Note: `runctap_minimal.m` takes as input a small dataset included under `~/ctap/data/`, which it uses to generate synthetic data and illustrate several preprocessing steps. To have it find the data, set the Matlab current directory to the root of the CTAP repo you have just cloned, i.e. `<destination dir>`. You can also set the output directory in `runctap_minimal.m`

More examples are available under `~/ctap/templates/`.

### How to run the analysis on FIOH BWRC (Linux) machines###

1. Clone the github repo:
	git clone https://github.com/bwrc/ctap.git <destination dir>

2. Start matlab with the root of the ctap repo as working dir.

3. Run
	update_matlab_path_anyone()
4. Try running one of the "proof-of-concept" scripts:
	pipebatch_minimal()	
	pipebatch_WCST_baseprepro()

## License information

CTAP is released under the MIT license, but depends on some components released under different licenses. Please refer to the file "LICENSE" for license information for the CTAP software, and for terms and conditions for usage, and a disclaimer of all warranties.

CTAP also depends on other software projects with different licenses. These are included with their respective licences in the `dependencies` folder.
