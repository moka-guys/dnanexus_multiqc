---
Using MultiQC:
  Installation: installation.md
  Running MultiQC: usage.md
  Using Reports: reports.md
  Configuration: config.md
  Customising Reports: customisation.md
  Common Problems: troubleshooting.md
MultiQC Modules:
  Pre-alignment:
    Cutadapt: modules/cutadapt.md
    FastQC: modules/fastqc.md
    FastQ Screen: modules/fastq_screen.md
    Skewer: modules/skewer.md
    Trimmomatic: modules/trimmomatic.md
  Aligners:
    Bismark: modules/bismark.md
    Bowtie 1: modules/bowtie1.md
    Bowtie 2: modules/bowtie2.md
    HiCUP: modules/hicup.md
    Kallisto: modules/kallisto.md
    STAR: modules/star.md
    Salmon: modules/salmon.md
    TopHat: modules/tophat.md
  Post-alignment:
    Bamtools: modules/bamtools.md
    Bcftools: modules/bcftools.md
    featureCounts: modules/featureCounts.md
    GATK: modules/gatk.md
    Methyl QA: modules/methylQA.md
    Picard: modules/picard.md
    Preseq: modules/preseq.md
    Qualimap: modules/qualimap.md
    Quast: modules/quast.md
    RSeQC: modules/rseqc.md
    Samblaster: modules/samblaster.md
    Samtools: modules/samtools.md
    SnpEff: modules/snpeff.md
Coding with MultiQC:
  Writing new templates: templates.md
  Writing new modules: modules.md
  Plotting Functions: plots.md
  MultiQC Plugins: plugins.md
---

# Welcome!

## MultiQC v0.8 Documentation

MultiQC is a tool to aggregate bioinformatics results across many samples
into a single report. It's written in Python and contains modules for a number
of common tools.

The documentation has the following pages:

 - [Docs homepage](README.md) _(this README file)_
 - Using MultiQC
   - [Installing MultiQC](installation.md)
   - [Running MultiQC](usage.md)
   - [Using Reports](reports.md)
   - [Configuration](config.md)
   - [Troubleshooting](troubleshooting.md)
 - MultiQC Modules
   - [FastQC](fastqc.md)
 - Coding with MultiQC
   - [Writing new templates](templates.md)
   - [Writing new modules](modules.md)
   - [Plugins](plugins.md)
   - [JavaScript](javascript.md)

These docs can be read in any of three ways:
 - On the MultiQC Website: http://multiqc.info
 - On GitHub: https://github.com/ewels/MultiQC/
 - As part of the distributed source code (in `/docs/`)
 
If you're curious how the website works, check out the
[MultiQC website repository](https://github.com/ewels/MultiQC_website).

## Contributing to MultiQC

If you write a module which could be of use to others, it would be great to
merge those changes back into the core MultiQC project.

For instructions on how best to do this, please see the
[contributing instructions](https://github.com/ewels/MultiQC/blob/master/CONTRIBUTING.md).
