# Truvari Benchmarking Pipeline

## Overview
This pipeline prepares a reference genome (GRCh38), cleans and normalizes both benchmark Genome in a Bottle (GIAB) HG002 and sample VCF files, filters BED regions, and benchmarks structural variants using Truvari. The pipeline outputs summary statistics, categorized VCFs, and performance metrics for true positives (TP), false positives (FP), false negatives (FN), and genotype mismatches to Google Cloud.

---

## Requirements
- Bash (`#!/usr/bin/env bash`)
- [samtools](http://www.htslib.org/)
- [bcftools](http://www.htslib.org/)
- [GATK](https://gatk.broadinstitute.org/)
- [Truvari](https://github.com/spiralgenetics/truvari)
- [gsutil](https://cloud.google.com/storage/docs/gsutil) 
- Reference genome: `GCA_000001405.15_GRCh38_no_alt_analysis_set.fna`
- Benchmark VCF: `HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.broad-header.vcf.gz`
- BED file of regions to include/exclude: `GCA_000001405.15_GRCh38_GRC_exclusions.bed`
- Sample VCF

---

## Inputs
- Reference FASTA: `REF="GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"`
- Benchmark VCF: `GIAB_VCF="HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.broad-header.vcf.gz"`
- Sample VCF: `SAMPLE_VCF="normNA24385_NA24385_O1D1_SM-G947H_v1.hard-filtered.vcf.gz"`
- BED file: `BED_ORIG="GCA_000001405.15_GRCh38_GRC_exclusions.bed"`
- Google Cloud Storage directory: `GCS_DIR="gs://..."`

---

## Outputs
- Normalized benchmark VCF: `HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.norm.vcf.gz`
- Normalized sample VCF: `normNA24385.final.vcf.gz`
- Cleaned BED file: `GCA_000001405.15_GRCh38_GRC_exclusions.clean.bed`
- Truvari results directory: `truvari_output/` containing:
  - `summary.txt`
  - `tp.vcf`, `fp.vcf`, `fn.vcf`
  - Additional statistics and log files

---

## Usage
Set your working directory in the script:
   ```bash
   WD="/path/to/working/directory"
