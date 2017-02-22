#!/bin/bash
#

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

#read the api key as a variable
API_KEY=$(cat '/home/dnanexus/auth_key')

#cd to the folder which multiqc will run in
cd to_test

# download the desired inputs. Use the input $project_for_multiqc to build the path to look in.
dx download $project_for_multiqc:QC/*base_distribution_by_cycle_metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*hsmetrics* --auth $API_KEY
dx download $project_for_multiqc:QC/*insert_size_metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*output.metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*stats-fastqc.txt --auth $API_KEY

# capture the variable $NGS_run to rename the multiqc output
for file in *base*; do 
	NGS_run=$(echo $file | cut -d'_' -f 1); 
done

# cd back to home
cd ..

# install Anaconda
bash ~/Anaconda2-4.2.0-Linux-x86_64.sh -b -p $HOME/Anaconda

#export to path
export PATH="$HOME/Anaconda/bin:$PATH"

# build multiqc
cd MultiQC
python setup.py install
cd ..

#make output folder
mkdir -p /home/dnanexus/out/multiqc/multiqc

# Run multiQC
# # command is : multiqc <dir containing files> -m module1 -m module2 -n <path/to/output>
multiqc /home/dnanexus/to_test/ -m fastqc -m picard -n /home/dnanexus/out/multiqc/multiqc/$NGS_run-multiqc.html


# Upload results
dx-upload-all-outputs
