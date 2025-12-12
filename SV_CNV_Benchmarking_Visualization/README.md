# Benchmarking Visualization for variant benchmarking files SNP/INDEL and SV/CNV

This repository contains R scripts for visualizing benchmarking metrics for genomic datasets, including large variants - Single Nucleotide Polymorphism, Insertion/Deletion (SNP/INDEL) and small variants - Structural Variant, Copy Number Variant (SV/CNV) analyses. The scripts load TSV benchmarking files, process and reshape the data, generate plots, and save figures for downstream analysis.

---

## Table of Contents

- [Overview](#overview)  
- [Scripts](#scripts)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Output](#output)  
- [Dependencies](#dependencies)  

---

## Overview

1. **SNP & INDEL Benchmarking Script** (`HG002_SNP_INDEL_benchmarking.R`)  
   - Loads multiple TSV benchmarking files from DRAGEN experiments.  
   - Filters by variant type (SNP or INDEL) and selects Whole Genome samples.  
   - Extracts sample identifiers from `Query_Name`.  
   - Adds coverage labels and organizes intervals.  
   - Reshapes metrics (`Precision`, `Recall`, `F1 Score`) into long format.  
   - Generates individual plots for SNP and INDEL metrics and a combined plot.  
   - Saves all plots as PNG files in a specified output directory.

2. **SV & CNV Benchmarking Script** (`SV_CNV_benchmarking.R`)  
   - Loads a single TSV file with SV/CNV benchmarking results.  
   - Cleans the data by removing unnecessary rows.  
   - Reshapes metrics (`TRUTH_TP`, `QUERY_TP`, `TRUTH_FN`, `QUERY_FP`, `PREC`, `RECALL`, `F1_SCORE`, `COVERAGE`) into long format.  
   - Converts relevant columns (`sample`, `replicate`, `bed_file`) to factors.  
   - Generates bar plots of all metrics across samples and replicates.  
   - Optionally generates line plots to visualize trends across replicates.

---

## Installation

Have **R** installed. Then, install the required R packages:

```R
install.packages(c("dplyr", "tidyr", "ggplot2", "patchwork", "stringr", "readr"))
