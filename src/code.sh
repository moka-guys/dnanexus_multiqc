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

# Files in the QC folder are placed there by third-party QC programs before being downloaded to the worker
# download the desired inputs. Use the input $project_for_multiqc to build the path to look in.
dx download $project_for_multiqc:QC/*base_distribution_by_cycle_metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*hsmetrics* --auth $API_KEY
dx download $project_for_multiqc:QC/*insert_size_metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*output.metrics --auth $API_KEY
dx download $project_for_multiqc:QC/*stats-fastqc.txt --auth $API_KEY
dx download $project_for_multiqc:QC/ped\.* --auth $API_KEY
dx download $project_for_multiqc:QC/*selfSM --auth $API_KEY

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

# install Anaconda
bash ~/Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/Miniconda

#export to path
export PATH="$HOME/Miniconda/bin:$PATH"

conda install jinja2 click markupsafe simplejson freetype networkx=1.11 -y

WES=FALSE
#determine if need to use multiqc @ 20X or 30X 
#WES=FALSE
for f in ~/to_test/* ; do 
	if [[ $f == *Pan493* ]]; then 
		WES=TRUE
 	fi
done
echo $WES

# Clone and install MultiQC from master branch of moka-guys fork
git clone https://github.com/moka-guys/MultiQC.git
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
# Command is : multiqc <dir containing files> -n <path/to/output> -c </path/to/config>
multiqc /home/dnanexus/to_test/ -n /home/dnanexus/out/multiqc/QC/multiqc/$NGS_date-multiqc.html -c /home/dnanexus/to_test/multiqc_config.yaml

# Upload results
dx-upload-all-outputs
