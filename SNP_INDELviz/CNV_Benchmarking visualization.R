
# Full Working R Script for SV/CNV Benchmarking Visualization

# Load Libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# 1. Load TSV File

file_path <- "/Users/jtseng/Documents/TAG/2325/simplebenchmarking/tag_2325/SVprecisionrecall.tsv"

df <- read.delim(file_path, header = TRUE, sep = "\t")

# 2. Remove Rows 1 and 7
df <- df[-c(1, 7), ]

# 3. Reshape into Long Format
df_long <- df %>%
  pivot_longer(
    cols = c(TRUTH_TP, QUERY_TP, TRUTH_FN, QUERY_FP, PREC, RECALL, F1_SCORE, COVERAGE),
    names_to = "metric",
    values_to = "value"
  )

# Ensure factors exist if sample, replicate, or bed_file are present
if ("sample" %in% colnames(df)) {
  df_long$sample <- as.factor(df_long$sample)
}

if ("replicate" %in% colnames(df)) {
  df_long$replicate <- as.factor(df_long$replicate)
}

if ("bed_file" %in% colnames(df)) {
  df_long$bed_file <- as.factor(df_long$bed_file)
}

# 4. Bar Plot of All Metrics Across Samples and Replicates
plot_metrics <- ggplot(df_long, aes(x = interaction(sample, replicate), y = value, fill = replicate)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8)) +
  facet_wrap(~ metric, scales = "free_y") +
  theme_bw(base_size = 12) +
  labs(
    title = "Benchmarking Metrics by Sample and Replicate",
    x = "Sample (Replicate)",
    y = "Metric Value",
    fill = "Replicate"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Print
print(plot_metrics)

# 5. Line Plot Version (Optional)
plot_trends <- ggplot(df_long, aes(x = replicate, y = value, group = sample, color = sample)) +
  geom_line(aes(linetype = sample)) +
  geom_point(size = 2) +
  facet_wrap(~ metric, scales = "free_y") +
  theme_bw() +
  labs(
    title = "Benchmarking Trends Across Replicates",
    y = "Metric Value",
    x = "Replicate"
  )

# Print
print(plot_trends)