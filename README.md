# dnanexus_multiqc v 1.1

## What does this app do?
This app runs MultiQC to generate run wide QC using the outputs from Picard CalculateHsMetrics, MarkDuplicates and CollectMultipleMetrics and FastQC

## What are typical use cases for this app?
This app should be performed after each run. It can be run automatically using the --depends-on flag or manually.

## What data are required for this app to run?
A project number is passed to the app as a parameter.
This project must have a folder 'QC' within the root of the project.
This folder must contain the following files:
* stats-fastqc.txt
* insert_size_metrics
* hsmetrics.tsv
* base_distribution_by_cycle_metrics
* output.metrics

## What does this app output?
1. A HTML QC report which should be uploaded to stickie.be
2. A folder containing the output in text format.

The outputs are placed in /QC/multiqc

## How does this app work?
* The app parses the file names to determine if the samples are WES or custom panels.

 * If WES coverage is reported at 20X
 * If not WES coverage is reported at 30X

## What are the limitations of this app
If the run is a mix of WES and non-WES coverage will be reported at 20X.

## This app was made by Viapath Genome Informatics 



