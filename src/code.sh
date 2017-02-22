#!/bin/bash
#

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

dx-download-all-inputs

# make a directory to move all inputs into

# Loop through the inputs folder, move all files into the same folder (each input has a folder /in/inputname and within this folder each input is within it's own folder eg /in/inputname/1, /in/inputname/2 etc)
inputs=/home/dnanexus/in/
ls $inputs
#for each input (eg hsmetrics, base_distribution_by_cycle_metrics, insert_size_metrics, stats_fastqc and output.metrics)
for input in `ls $inputs`; do
	# go through each numbered folder
	for sample_input in `ls $inputs/$input`; do
		#and move the file into ~/allinputs
		mv $inputs$input/$sample_input/* ~/to_test/
	done
done


bash ~/Anaconda2-4.2.0-Linux-x86_64.sh -b -p $HOME/Anaconda
export PATH="$HOME/Anaconda/bin:$PATH"

cd MultiQC
python setup.py install
cd ..

mkdir -p /home/dnanexus/out/multiqc/multiqc
# #
# # Run multiQC
# #
# # command is : multiqc <dir containing files> -m module1 -m module2 -n <path/to/output>
multiqc /home/dnanexus/to_test/ -m fastqc -m picard -n /home/dnanexus/out/multiqc/multiqc/$runfolder-multiqc.html

#
# Upload results
#
#mark-section "uploading results"

dx-upload-all-outputs
#mark-success
