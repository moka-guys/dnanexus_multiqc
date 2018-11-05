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
        out_template: a jinja2-formatted picard mark duplicates template file
    """
    # Get sample name from input file name. Parent directories are removed and multi-extension
    # suffixes are split into a list. The first item is returned, containing the sample name.
    # Get the sample filename without directory prefixes. E.g.:
    #    /home/user/inputfile.txt ---> inputfile.txt
    sample_basename = os.path.basename(mapping_metrics)
    # Remove the extension from the sample name. os.path.splitext splits the filename into a string,
    # delimited by the extension. E.g.:
    #    os.path.splitext("myfile1.txt") --> [ 'myfile', '.txt' ]
    # This is selected by index [0] to get the first item, which is the sample name 
    sample = os.path.splitext(sample_basename)[0]

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
        # Delimit line by ',' and take the last entry. This contains the percentage of duplicates marked,
        # which must be divided by 100 to be accurately represented in the output MultiQC report.
        perc_dup = float(perc_dups_line.split(",")[-1])/100

    # Generate new template content with sample details from dragen mapping metrics
    with open(out_template, "r") as infile:
        # Read template file as a jinja2.Template object and map variables with Template.render()
        template = Template(infile.read())
        output = template.render(sample=sample, percent_duplication=perc_dup)

    # Write new output metrics file for sample
    with open("{}.output.metrics".format(sample), "w") as outfile:
        outfile.write(output)

def main(args):
    """Convert markduplicate files passed to command-line argument"""
    # Get command line arguments
    parser = argparse.ArgumentParser()
    # Add argument for template
    parser.add_argument("-t", "--template", help="Template file resembling picard output.metrics")
    # Add argument for input. nargs '+' collects all arguments from the command line to a list.
    parser.add_argument("inputs", help="input files from dragen markduplicates", nargs='+')
    parsed = parser.parse_args(args)

    # Loop over the input file argments. Where the script is given input files as *.csv,
    # parsed.inputs --> ['file1.csv', 'file2.csv', 'file3.csv'...]
    for infile in parsed.inputs:
        # Run the reformatting protocol on all script input files. The reformatting function requires
        # a jinja2-formatted template file, read from the command line as parsed.template
        reformat(infile, out_template=parsed.template)

if __name__ == '__main__':
    main(sys.argv[1:])
