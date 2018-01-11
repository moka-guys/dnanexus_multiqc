#!/bin/bash
#

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

# capture the variable $NGS_date from the runname variable to rename the multiqc output
NGS_date=$(echo $project_for_multiqc | cut -d'_' -f 2);

#read the api key as a variable
API_KEY=$(cat '/home/dnanexus/auth_key')

# make and cd to the folder which multiqc will run in
mkdir to_test
cd to_test

# *MOST* QC files are stored at /QC/
# to make this futureproof download entire contents of this folder within $project_for_multiqc.
dx download $project_for_multiqc:QC/* --auth $API_KEY

# check if there are any dragen output files
# list all files which match the string in the output folder
# pass this list to grep using -c which just outputs the count
mapping_metrics_count=$(dx ls $project_for_multiqc:/output/*mapping_metrics.csv --auth K2v2COMKM7NdjeHyWdINUSrCrHaJfnxZ | grep -c mapping_metrics)

# if there are files to download
if $mapping_metrics_count > 0:
	# download them
	dx download $project_for_multiqc:/output/*mapping_metrics.csv --auth K2v2COMKM7NdjeHyWdINUSrCrHaJfnxZ
fi


# Stats.json is uploaded with the runfolder in Data/Intesities/BaseCalls/Stats/.
# This search makes sure it is found in the project/runfolder regardless of project name:
# 
# If "Stats.json" is present, the `dx find data` command below returns: 
# closed  2017-09-25 10:15:46 122.23 KB /Data/Intensities/BaseCalls/Stats/Stats.json (file-F74GXP80QBG98Xg2Gy4G7ggF)
# The command `cut -f8 -d ''` extracts the file ID from the eight field of this string, using space as a delimiter.
# The command `tr -d '()'` deletes bracket characters from the file ID.
#
# When the commands are piped in the order mentioned and a "Stats.json" file is present, then 
# $stats_json="file-F74GXP80QBG98Xg2Gy4G7ggF", else $stats_json="".
stats_json=$(dx find data --path ${project_for_multiqc}: --name "Stats.json" | cut -f8 -d ' ' | tr -d '()')

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
dx download project-ByfFPz00jy1fk6PjpZ95F27J:file-F9F0fgj0jy1y61bzJj45Yp0X  --auth $API_KEY

# install Anaconda
bash ~/Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/Miniconda

#export to path
export PATH="$HOME/Miniconda/bin:$PATH"
# use conda to download all packages required
conda install jinja2 click markupsafe simplejson freetype networkx=1.11 -y

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
multiqc /home/dnanexus/to_test/ -n /home/dnanexus/out/multiqc/QC/multiqc/$NGS_date-multiqc.html -c $multiqc_config

# copy the config file used to output folder
mv $multiqc_config /home/dnanexus/out/multiqc/QC/multiqc/

# Upload results
dx-upload-all-outputs
