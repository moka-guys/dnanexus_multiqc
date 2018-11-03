# dnanexus_multiqc v 1.7
ewels/MultiQC [v1.6](https://github.com/ewels/MultiQC/)

## What does this app do?
This app runs MultiQC to generate run wide quality control (QC) using the outputs from MokaPipe and MokaWES pipelines including:
* Picard (CalculateHsMetrics, MarkDuplicates and CollectMultipleMetrics)
* FastQC 
* bcl2fastq2
* Peddy
* verifyBAMID

## What are typical use cases for this app?
To generate QC reports, this app should be run at the end of an NGS pipeline, when all QC software outputs are available.

## What data are required for this app to run?
A project number is passed to the app as a parameter. This project must have a 'QC' folder in its root directory. All files from this folder are downloaded by the app and parsed using MultiQC

Additional QC files are downloaded from other locations:
* If demultiplexing was performed by bcl2fastq v2.20 (or later) 'Stats.json' is downloaded from  /runfolder/Data/Intensities/BaseCalls/Stats 
* If the MokaWES pipeline was run, mapping_metrics.csv files are downloaded from /output.

## What does this app output?
1. A HTML QC report (with the name of the runfolder) which should be uploaded to stickie.be
2. A folder containing the output in text format.

The outputs are placed in the project under '/QC/multiqc'

## How does this app work?
* The app parses the file names to determine if any of the samples are WES samples (Pan493). If yes, coverage is reported at 20X. Else, coverage is reported at 30X. The app edits the bundled 'dnanexus_multiqc_config.yaml' to reflect this. The parameters in this file are then passed with calls to MultiQC.
* The app converts dragen mapping metrics files to the picard markduplicates file format. The percantage duplicates metric from dragen is then reported in the MultiQC stats table for these samples. The script to make the conversion ('convert_mapping_metrics.py') is bundled with the app, along with the picard output.metrics template it requires.  

## What are the limitations of this app
* If the run is a mix of WES and non-WES coverage will be reported at 20X.
* The project which MultiQC is run on must be shared with the user mokaguys

## This app was made by Viapath Genome Informatics 
