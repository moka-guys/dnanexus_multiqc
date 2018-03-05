# dnanexus_multiqc v 1.4
ewels/MultiQC [v1.4](https://github.com/ewels/MultiQC/)

## What does this app do?
This app runs MultiQC to generate run wide QC using the outputs from MokaPipe and MokaWES pipelines including:
* Picard (CalculateHsMetrics, MarkDuplicates and CollectMultipleMetrics)
* FastQC 
* bcl2fastq2
* Peddy
* verifyBAMID

This app uses a fork of MultiQC at [https://github.com/moka-guys/MultiQC]:https://github.com/moka-guys/MultiQC

## What are typical use cases for this app?
This app should be performed after each run. It can be run automagically using the --depends-on flag or manually.

## What data are required for this app to run?
A project number is passed to the app as a parameter.
This project must have a folder 'QC' within the root of the project.
All files from this folder are downloaded and parsed by MultiQC

QC files are also downloaded from other locations:
* If demultiplexing was performed by bcl2fastq v2.20 (or later) 'Stats.json' is downloaded from  /runfolder/Data/Intensities/BaseCalls/Stats 
* If the MokaWES pipeline was run, mapping_metrics.csv files are downloaded from /output.

The miniconda installation script is downloaded from 001_ToolsReferenceData:/Data/Miniconda/Miniconda2-latest-Linux-x86_64.sh

## What does this app output?
1. A HTML QC report (with the name of the runfolder) which should be uploaded to stickie.be
2. A folder containing the output in text format.

The outputs are placed in /QC/multiqc

## How does this app work?
* The app parses the file names to determine if any of the samples are WES samples (Pan493).

 * If yes, coverage is reported at 20X
 * Else, coverage is reported at 30X

## What are the limitations of this app
If the run is a mix of WES and non-WES coverage will be reported at 20X.
The project which MultiQC is run on must be shared with the user mokaguys

## This app was made by Viapath Genome Informatics 
