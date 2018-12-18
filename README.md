# dnanexus_multiqc v 1.8
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
* 'Stats.json' is downloaded from  /runfolder/Data/Intensities/BaseCalls/Stats if demultiplexing was performed by bcl2fastq v2.20 (or later) 
* \*duplication_metrics or \*mapping_metrics.csv files are downloaded from /output if the MokaWES pipeline was run.

## What does this app output?
The following outputs are placed in the DNAnexus project under '/QC/multiqc':
* A HTML QC report (with the name of the runfolder) which should be uploaded to the Viapath Genome Informatics server.
* A folder containing the output in text format.

## How does this app work?
1. The app downloads files found in the QC/ directory of the project.
2. The dx_find_and_download function is used to search for specific files, which are downloaded only if found.
3. If dragen mapping metrics files are present, the app converts them to the picard markduplicates file format. This allows the percentage duplicates metric from dragen to be reported in the MultiQC stats table for these samples. The script to make the conversion ('convert_mapping_metrics.py') is bundled with the app, along with the picard output.metrics template it requires.
4. The app sets the minimum-fold coverage reported in the general stats table by editing 'dnanexus_multiqc_config.yaml'. This value comes from the app's 'coverage_level' input parameter, the default for which is 30X. If the WES panel number (Pan493) is present in any of the input sample names, coverage is set to 20X.
5. A dockerised version of MultiQC is used. The docker image is stored on DNAnexus as an asset, which is bundled with the app build. The following commands were used to generate this asset in a cloud workstation:
    * `docker pull ewels/multiqc:v1.6`
    * `dx-docker create-asset ewels/multiqc:v1.6`
    * The asset on DNAnexus was then renamed with the following command: `dx mv ewels\\multiqc\\:v1.6 ewels_multiqc_v1.6`
6. The MultiQC outputs are uploaded to DNAnexus.

## What are the limitations of this app
* If the run is a mix of WES and non-WES coverage will be reported at 20X.
* The project which MultiQC is run on must be shared with the user mokaguys
* Only one value can be given to the coverage_level parameter, which may not be ideal for runs with mixed samples. Multiple reports may be required in these cases

## This app was made by Viapath Genome Informatics 
