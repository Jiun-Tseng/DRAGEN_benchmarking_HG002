# Bland-Altman Summary Statistics for SNP/INDEL Metrics

This R script performs Bland-Altman analysis to compare benchmarking metrics between two experimental conditions across SNP and INDEL variant types. The analysis focuses on sequenced metrics such as Precision, Recall, and F1 Score.

---

## Overview

- Combines long-format SNP and INDEL data (`HG130_SNP_long` and `HG130_INDEL_long`).  
- Filters for two experiments:  
  - `"hard-polyg-3-5prime-adapter"`  
  - `"soft-polyg-3-adapter"`  
- Reshapes the data into wide format so that metrics for each experiment are in separate columns.  
- Performs Bland-Altman statistical analysis using the [`blandr`](https://cran.r-project.org/package=blandr) package.  
- Calculates:  
  - t-statistic and degrees of freedom  
  - p-value  
  - Bias and its 95% confidence interval  
  - Limits of Agreement (LoA) and their confidence intervals  
  - Number of comparisons  

- Saves the summary statistics as a CSV file for downstream analysis.

---

## Instructions

Install the following R packages:

```R
install.packages(c("blandr", "dplyr", "tidyr"))
