#!/bin/bash

# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -e -x -o pipefail

find_dragen_qc() {
    # Check if there are any dragen output files (suffix 'mapping_metrics.csv') using dx find data and
    # pipe this to wc -l to count the number of files found.
    mapping_metrics_count=$(dx find data --path ${project_for_multiqc}: --name "*mapping_metrics.csv" --auth $API_KEY | wc -l)

    # Download dragen output files if ${mapping_metrics_count} does not equal 0. Else continue
    if [ $mapping_metrics_count -ne 0 ]; then
        dx download $project_for_multiqc:/output/*mapping_metrics.csv --auth $API_KEY
		# Convert dragen mapping metrics files to picard markduplicates format for recognition by multiqc
		python convert_mapping_metrics.py -t template.output.metrics *mapping_metrics.csv
        # Delete the template file so it does not appear in the multiqc report
        rm template.output.metrics
    else
        echo "INFO: No mapping metrics files in output folder"
    fi
}

find_bcl2fastq_qc() {
    # Search for the file bcl2fastq QC file ("Stats.json") using `dx find data`. If the file is found,
    # the command returns the following string, which is piped to egrep to extract the file ID with a regular expression:
    # closed  2017-09-25 10:15:46 122.23 KB /Data/Intensities/BaseCalls/Stats/Stats.json (file-F74GXP80QBG98Xg2Gy4G7ggF)
    # File present: ${stats_json} --> "file-F74GXP80QBG98Xg2Gy4G7ggF"
    # File not found: ${stats_json} --> ""
    stats_json=$(dx find data --path ${project_for_multiqc}: --name "Stats.json" --auth $API_KEY | egrep -o 'file-\w+' )
    # Download "Stats.json" if found, by testing that a file ID was saved to the $stats_json variable
    # [[ string =~ ^"pattern" ]]; performs regular expression match that 'string' starts with 'pattern'
    if [[ $stats_json =~ ^"file" ]]; then 
        dx download $stats_json --auth $API_KEY
    else
        echo "No Stats.json file found in /Data/Intensities/BaseCalls/Stats/, bcl2fastq2 stats not included in summary"
    fi
}

set_general_stats_coverage() {
    # Format dnanexus_multiqc_config.yaml file general stats coverage column based on project inputs.
    # If coverage_level is given as a script option, store it in the config_cov variable.
    # This uses the bash test option -z which, when negated with !, returns True if $coverage_level is not empty.
    if [[ ! -z $coverage_level ]]; then
        config_cov=$coverage_level
    # Else if WES samples are present, set the coverage to 30 by searching for Pan493 in filename
    elif [ $(ls $HOME | grep Pan493 | wc -l) -ne 0 ]; then
        config_cov="20"
    # In all other cases, leave the coverage to 30X, which is the default value in the config yaml
    else
        config_cov="30"
    fi
	# Edit config to report general stats minimum coverage at the value set.
    # Here, the sed command uses 'n;' to substitute the default coverage in the config file (30),
    # for the value set in ${config_cov}.
	sed -i "/general_stats_target_coverage/{n;s/30/${config_cov}/}" dnanexus_multiqc_config.yaml
}

main() {

    # SET VARIABLES
    # Store the API key. Grants the script access to DNAnexus resources    
    API_KEY=$(cat '/home/dnanexus/auth_key')
    # Capture the project runfolder name. Names the multiqc HTML input and builds the output file path
    project=$(echo $project_for_multiqc | sed 's/002_//')
    # Assign multiqc output directory name to variable and create
    outdir=out/multiqc/QC/multiqc && mkdir -p ${outdir}
    # Assing multiqc report output directory name to variable and create
    report_outdir=out/multiqc_report/QC/multiqc && mkdir -p ${report_outdir}

    # Files for multiqc are stored at 'project_for_multiqc:/QC/''. Download the contents of this folder.
    dx download ${project_for_multiqc}:QC/* --auth ${API_KEY}

    # Download and reformat dragen markduplicates files as picard files if found in the project
    find_dragen_qc

    # Download bcl2fastq QC files if found in the project
    find_bcl2fastq_qc

    # Format dnanexus_multiqc_config.yaml file general stats coverage column based on project inputs
    set_general_stats_coverage

    # Pull multiqc docker image to cloud worker
    dx-docker pull ewels/multiqc:v1.6
    # Call multiQC with the following parameters :
    #    multiqc <dir containing files> -n <path/to/output> -c </path/to/config>
    dx-docker run -v /home/dnanexus:/sandbox ewels/multiqc:v1.6 multiqc sandbox/ \
        -n sandbox/${outdir}/${project}-multiqc.html -c sandbox/dnanexus_multiqc_config.yaml

    # Move the config file to the multiqc data output folder. This was created by running multiqc
    mv dnanexus_multiqc_config.yaml ${outdir}/${project}-multiqc_data/
    # Move the multiqc report HTML to the output directory for uploading to the Viapath server
    mv ${outdir}/${project}-multiqc.html ${report_outdir}

    # Upload results
    dx-upload-all-outputs
}
