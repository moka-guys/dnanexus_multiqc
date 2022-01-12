# dnanexus_multiqc v1.15.0

## MultiQC version

The docker image applied in this release is [seglh/multiqc:v1.11](https://github.com/moka-guys/multiqc_plugins/releases/tag/v1.0.0) and is pulled from dockerhub.
This release is based on MultiQC [v1.11](https://github.com/ewels/MultiQC/) and incorporates a custom plugin to add support for som.py, exome depth and the TSO500 metrics.tsv file.

## What does this app do?

This app runs MultiQC to generate run wide quality control (QC) using the outputs from MokaAMP, MokaPipe, TSO500 and MokaWES
pipelines including:

* Picard (CalculateHsMetrics, MarkDuplicates and CollectMultipleMetrics, TargetedPcrMetrics)
* FastQC
* bcl2fastq2
* bclconvert
* Peddy
* verifyBAMID
* Sentieon (duplication_metrics)
* som.py ^
* TSO500 metrics.tsv ^
* exome depth ^

^ provided by SEGLH plugin.

## What are typical use cases for this app?

To generate QC reports, this app should be run at the end of an NGS pipeline, when all QC software outputs are available.

## What data are required for this app to run?

* project_for_multiQC - The name of the project to be assessed.
  * This project must have a 'QC' folder in its root directory.
* coverage_level - Define which column to display from hsmetrics, reporting the percentage of target bases covered at
the required depth (eg PCT_TARGET_BASES_20X)

Additional QC files are downloaded from other locations:

* 'Stats.json' is downloaded from  /runfolder/Data/Intensities/BaseCalls/Stats if demultiplexing was performed by
bcl2fastq v2.20 (or later)
* Any files with \*metrics\* in the name are downloaded. Sentieon apps output all files into the output folder, with
inconsistent naming between apps. eg Duplication_metrics and duplication_metrics.

## What does this app output?

The following outputs are placed in the DNAnexus project under '/QC/multiqc':

* A HTML QC report (with the name of the runfolder) which should be uploaded to the Viapath Genome Informatics server.
* A folder containing the output in text format.

## How does this app work?

1. The app downloads all files (recursively) within the QC/ directory of the project. 
2. The dx_find_and_download function is used to search for specific files, which are downloaded only if found.
3. The app sets the minimum-fold coverage reported in the general stats table by editing 
'dnanexus_multiqc_config.yaml'. This value comes from the app's 'coverage_level' input parameter.
4. A dockerised version of MultiQC is used.
5. MultiQC parses all files, including any recognised files in the report.
6. The MultiQC outputs are uploaded to DNAnexus.

## What are the limitations of this app

* The project which MultiQC is run on must be shared with the user mokaguys
* Only one value can be given to the coverage_level parameter, which may not be ideal for runs with mixed samples. 
Multiple reports may be required in these cases

## This app was made by Viapath Genome Informatics
