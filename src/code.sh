#!/bin/bash
#

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

#read the api key as a variable	
API_KEY=$(cat '/home/dnanexus/auth_key')

# capture the variable $NGS_date from the runname variable to rename the multiqc output
project=$(echo $project_for_multiqc | sed 's/002_//');


# make and cd to the folder which multiqc will run in
mkdir to_test
cd to_test

# *MOST* QC files are stored at /QC/
# to make this futureproof download entire contents of this folder within $project_for_multiqc.
dx download $project_for_multiqc:QC/*  --auth $API_KEY

# check if there are any dragen output files (named mapping_metrics.csv) using dx find
# pipe this to wc -l to find number of files found. if no files are found wc -l ==0 
mapping_metrics_count=$(dx find data --path ${project_for_multiqc}: --name "*mapping_metrics.csv" --auth $API_KEY | wc -l)

# if there are mapping metrics files to download
if [ $mapping_metrics_count -ne 0 ]
then
	# download them
	dx download $project_for_multiqc:/output/*mapping_metrics.csv --auth $API_KEY
	echo "downloading mapping metrics files"
else
	echo "no mapping metrics files in output folder"
fi


# Stats.json is uploaded with the runfolder in Data/Intesities/BaseCalls/Stats/.
# This search makes sure it is found in the project/runfolder regardless of project name:
# 
# If "Stats.json" is present, the `dx find data` command below returns: 
# closed  2017-09-25 10:15:46 122.23 KB /Data/Intensities/BaseCalls/Stats/Stats.json (file-F74GXP80QBG98Xg2Gy4G7ggF)
# The command `cut -f 2 -d '('` splits the string on '(' and takes the second item in the list .
# The command `tr -d ')'` deletes the close bracket character from the file ID.
#
# When the commands are piped in the order mentioned and a "Stats.json" file is present, then 
# $stats_json="file-F74GXP80QBG98Xg2Gy4G7ggF", else $stats_json="".
stats_json=$(dx find data --path ${project_for_multiqc}: --name "Stats.json" --auth $API_KEY | cut -f 2 -d '(' | tr -d '()')

# Test if the string contained in $stats_json starts with "file", then download, else continue.
# Confirms that a Stats.json file was found (non-empty string), and that the file ID was properly extracted by `cut` and `tr`
if [[ $stats_json =~ ^"file" ]]  # [[ string =~ pattern ]]; performs regular expression match on 'string' using 'pattern'
then 
dx download $stats_json --auth $API_KEY
else
echo "No Stats.json file found in /Data/Intensities/BaseCalls/Stats/, bcl2fastq2 stats not included in summary"
fi

# cd back to home
cd ..

####  Download and install Python and MultiQC
#download miniconda from 001
dx download project-ByfFPz00jy1fk6PjpZ95F27J:Data/Miniconda/Miniconda2-latest-Linux-x86_64.sh --auth $API_KEY

# install Anaconda
bash ~/Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/Miniconda

#export to path
export PATH="$HOME/Miniconda/bin:$PATH"

# use conda to download all packages required
conda install jinja2=2.10 click=6.7 markupsafe=1.0 simplejson=3.13.2 freetype=2.8 networkx=2.0 -y

# Clone and install MultiQC from master branch of moka-guys fork
git clone https://github.com/moka-guys/MultiQC.git

cd MultiQC
python setup.py install
cd ..

#### Set MultiQC parameters
#set flag to see if any WES samples are present
WES=FALSE

# set default config file to the 30X one
multiqc_config="/home/dnanexus/multiqc_config_30X.yaml"

# If any WES samples need to report coverage @ 20X - look for any WES samples
for f in ~/to_test/* ; do 
	# if Pan493 in the filename
	if [[ $f == *Pan493* ]]; then 
		# change the config file variable to point @ 20X config file
		multiqc_config="/home/dnanexus/multiqc_config_20X.yaml"
 	fi
done

#make output folder
mkdir -p /home/dnanexus/out/multiqc/QC/multiqc

# Run multiQC
# Command is : multiqc <dir containing files> -n <path/to/output> -c </path/to/config>
multiqc /home/dnanexus/to_test/ -n /home/dnanexus/out/multiqc/QC/multiqc/$project-multiqc.html -c $multiqc_config

# copy the config file used to multiqc data output folder
mv $multiqc_config /home/dnanexus/out/multiqc/QC/multiqc/$project-multiqc_data/

# Upload results
dx-upload-all-outputs
