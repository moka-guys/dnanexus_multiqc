#!/usr/bin/env python3
"""Convert dragen markduplicates files (DNAnexusProject:/output/*mapping_metrics.csv) to picard
markduplicates format for processing with multiqc. Transfers the 'duplicate reads' value only, which
is presented in the multiqc general stats table. Output files are named by replacing the 
'mapping_metrics.csv' suffix with 'output.metrics'.

Example usage:
    python convert_mapping_metrics.py *mapping_metrics.csv
"""
import os
import sys
import argparse
from jinja2 import Template


def reformat(mapping_metrics, out_template):
    """Reformat dragen mapping metrics to picard markduplicates format.
    Args:
        mapping_metrics: a dragen mark duplicates filename
        out_template: a jinja2-formatted picard mark duplicates template filename
    """
    # Get sample name from input file name. Parent directories are removed and multi-extension
    # suffixes are split into a list. The first item is returned, containing the sample name.
    sample = os.path.basename(mapping_metrics).split(os.extsep, 1)[0]

    # Open the input dragen mapping metrics file and get the percentage duplicates value
    with open(mapping_metrics, 'r') as infile:
        perc_dups_line = list(
            filter(
                # Find line that contains both strings tested in function below
                lambda line: ("Number of duplicate reads" in line) and ("PER RG" in line),
                infile.readlines()
                )
            # Return as string variable
            ).pop()
        # Delimit line by ',' and take the last entry. This contains the percentage of duplicates marked.
        perc_dup = float(perc_dups_line.split(",")[-1])/100

    # Generate new template content with sample details from dragen mapping metrics
    with open(out_template, "r") as infile:
        template = Template(infile.read())
        output = template.render(sample=sample, percent_duplication=perc_dup)

    # Write new output metrics file for sample
    with open("{}.output.metrics".format(sample), "w") as outfile:
        outfile.write(output)

def main(args):
    """Convert markduplicate files passed to command-line argument"""
    # Get command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-t", "--template", help="Template file resembling picard output.metrics")
    parser.add_argument("inputs", help="input files from dragen markduplicates", nargs='+')
    parsed = parser.parse_args(args)

    # Run reformatting protocol on all input files given to script
    for infile in parsed.inputs:
        reformat(infile, out_template=parsed.template)

if __name__ == '__main__':
    main(sys.argv[1:])
