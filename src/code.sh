#!/bin/bash

# Exit at any point if there is any error and output each line as it is executed (for debugging)
set -e -x -o pipefail

dx_find_and_download() {
    # Download files from DNANexus project if present.
    #
    # Args:
    #    $1 / name: A wildcard to capture matching files in the project.
    #    $2 / project: A DNAnexus project to search
    #    $3 / max_find: Integer. Function fails if more than this number of files is found. If no argument
    #        is given, downloads all files found.

    # Map input arguments to variables
    name=$1
    project=$2
    max_find=$3

    # Search input DNANexus project for files matching name string. Store to variable file_ids.
    # `dx find data` returns a single space-delimited string. This result is warpped in parentheses creating a bash
    # #array.
    # Example with two matching files: echo ${file_ids[@]}
    # > project-FP7Q76j07v81kb4564qPFyb1:file-FP96Pp80Vf2bB7ZqJBbzbvp5
    # project-FP7Q76j07v81kb4564qPFyb1:file-FP96Q3801p85KY2g7GPfP6J6
    # $name in double quotes to ensure correct usage of wildcards passed into function eg ensure the string *metrics*
    # is passed into dx find and not a list of files containing metrics in filename
    file_ids=( $(dx find data --brief --path "${project}": --name "$name" --auth "$API_KEY"))

    files_found=${#file_ids[@]} # ${#variable[@]} gives the number of elements in array $variable

    # Continue if no files found matching $name in $project
    if [ "$files_found" -eq 0 ]; then
        echo "Nothing to download in $project matching $name."
    # Else if an integer was given as the max_find argument
    elif [[ $max_find =~ [0-9]+ ]]; then
        # Download if number of files found is less than or equal to the max argument
        if [ "$files_found" -le "$max_find" ]; then
            # as dx find is recursive -f any files which match this search term but were previously downloaded will be
            # over written to prevent duplicate files.
            dx download ${file_ids[@]} -f --auth "$API_KEY"
        # Else raise error
        else
            echo "Found $files_found files with name $name in $project. Expected $max_find files or less."
            exit 1
        fi
    # Else download all files found using -f to overwrite duplicate files
    else
        dx download ${file_ids[@]} -f --auth "$API_KEY"
    fi
}

set_general_stats_coverage() {
    # Format dnanexus_multiqc_config.yaml file general stats coverage column based on project inputs.

    # coverage_level is given as an input, store it in the config_cov variable.
    config_cov=$coverage_level

    # Subsitute the default coverage in the config file for $config_cov
    #   - 'n;' makes the substitution occur on the line after the first instance of "general_stats_target_coverage"
	sed -i "/general_stats_target_coverage/{n;s/30/${config_cov}/}" dnanexus_multiqc_config.yaml
}

main() {
    # SET VARIABLES
    # Store the API key. Grants the script access to DNAnexus resources
    API_KEY=$(dx cat project-FQqXfYQ0Z0gqx7XG9Z2b4K43:mokaguys_nexus_auth_key)
    # Capture the project runfolder name. Names the multiqc HTML input and builds the output file path
    # shellcheck disable=SC2001
    project=$(echo "$project_for_multiqc" | sed 's/002_//')
    # Assign multiqc output directory name to variable and create
    outdir=out/multiqc/QC/multiqc && mkdir -p ${outdir}
    # Assing multiqc report output directory name to variable and create
    report_outdir=out/multiqc_report/QC/multiqc && mkdir -p ${report_outdir}

    # Files for multiqc are stored at 'project_for_multiqc:/QC'. Download the contents of this folder.
    dx download -r "${project_for_multiqc}":/QC --auth "${API_KEY}"

    # Download all metrics files from the project (this will include the duplication metrics files (named slightly
    # different by the various senteion apps))
    dx_find_and_download '*metrics*' "$project_for_multiqc"
    dx_find_and_download '*gene_level*' "$project_for_multiqc"

    # remove the template file so it doesn't appear on final report
    rm sention_output_metrics_header

    # Download bcl2fastq QC files if found in the project
    dx_find_and_download 'Stats.json' "$project_for_multiqc" 1

    # Format dnanexus_multiqc_config.yaml file general stats coverage column based on project inputs
    set_general_stats_coverage

    # MultiQC is run with the following parameters :
    #    multiqc <dir containing files> -n <path/to/output> -c </path/to/config>
    # The docker -v flag mounts a local directory to the docker environment in the format:
    #    -v local_dir:docker_dir
    # Multiqc searches for QC files. Docker passes any new files back to this mapped location on the DNAnexus worker.

    #get the multiqc docker and extract 
    multiqc_docker_file_id=project-ByfFPz00jy1fk6PjpZ95F27J:file-GX07bkj0jy1Qqjgb1v8FZvX6 # 001_ToolsReferenceData:/Data/Docker/multiqcv1.14_plugin_v1.4.0.tar.gz
    dx download ${multiqc_docker_file_id}
    multiqc_Docker_image_file=$(dx describe ${multiqc_docker_file_id} --name)
    multiqc_Docker_image_name=$(tar xfO "${multiqc_Docker_image_file}" manifest.json | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/')

    docker load < /home/dnanexus/"${multiqc_Docker_image_file}"

    echo "Using docker image ${multiqc_Docker_image_name}"


    docker run -v /home/dnanexus:/home/dnanexus --rm ${multiqc_Docker_image_name} /home/dnanexus/ \
        -n /home/dnanexus/${outdir}/"${project}"-multiqc.html -c /home/dnanexus/dnanexus_multiqc_config.yaml

    # Move the config file to the multiqc data output folder. This was created by running multiqc
    mv dnanexus_multiqc_config.yaml ${outdir}/"${project}"-multiqc_data/
    # Move the multiqc report HTML to the output directory for uploading to the Viapath server
    mv ${outdir}/"${project}"-multiqc.html ${report_outdir}

    # Upload results
    dx-upload-all-outputs
}
