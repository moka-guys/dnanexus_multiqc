#!/bin/bash
#

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

# capture the variable $NGS_date from the runname variable to rename the multiqc output
NGS_date=$(echo $project_for_multiqc | cut -d'_' -f 2); 

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

# cd back to home
cd ..

# install Anaconda
bash ~/Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/Miniconda

#export to path
export PATH="$HOME/Miniconda/bin:$PATH"

conda install jinja2 click markupsafe simplejson freetype -y

WES=FALSE
#determine if need to use multiqc @ 20X or 30X 
#WES=FALSE
for f in ~/to_test/* ; do 
	if [[ $f == *Pan493* ]]; then 
		WES=TRUE
 	fi
done
echo $WES

git clone https://github.com/ewels/MultiQC.git
cd MultiQC
python setup.py install
cd ..

if [[ $WES == TRUE ]]; then
	mv multiqc_config_20X.yaml to_test/multiqc_config.yaml
else
	mv multiqc_config_30X.yaml to_test/multiqc_config.yaml
fi

#make output folder
mkdir -p /home/dnanexus/out/multiqc/QC/multiqc

# Run multiQC
# # command is : multiqc <dir containing files> -m module1 -m module2 -n <path/to/output>
multiqc /home/dnanexus/to_test/ -m fastqc -m picard -n /home/dnanexus/out/multiqc/QC/multiqc/$NGS_date-multiqc.html -c /home/dnanexus/to_test/multiqc_config.yaml


# Upload results
dx-upload-all-outputs
