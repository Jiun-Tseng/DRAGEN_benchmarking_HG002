library(blandr)
library(dplyr)
library(tidyr)

metrics <- c("Precision", "Recall", "F1_Score")

combined_long <- bind_rows(HG130_SNP_long, HG130_INDEL_long) %>%
  filter(Experiment %in% c("hard-polyg-3-5prime-adapter", "soft-polyg-3-adapter"))

metrics_wide <- combined_long %>%
  unite(Metric_Experiment, Metric, Experiment, sep = "_") %>%
  pivot_wider(names_from = Metric_Experiment, values_from = Value) %>%
  drop_na()

results_list <- list()

for (metric in metrics) {
  hard_col <- paste0(metric, "_hard-polyg-3-5prime-adapter")
  soft_col <- paste0(metric, "_soft-polyg-3-adapter")
  
  x <- metrics_wide[[hard_col]]
  y <- metrics_wide[[soft_col]]
  
  stats <- blandr.statistics(x, y)
  
  results_list[[metric]] <- c(
    Metric = metric,
    t_statistic = stats$t.statistic,
    df = stats$df,
    p_value = stats$p.value,
    bias = stats$bias,
    bias_lower_CI = stats$biasLowerCI,
    bias_upper_CI = stats$biasUpperCI,
    LoA_lower = stats$lowerLOA,
    LoA_upper = stats$upperLOA,
    LoA_lower_CI = stats$lowerLOALowerCI,
    LoA_upper_CI = stats$lowerLOAUpperCI,
    LoA_lower_Upper_CI = stats$lowerLOAUpperCI,  # optional
    LoA_upper_Lower_CI = stats$upperLOALowerCI,  # optional
    num_comparisons = stats$n
  )
}

results_df <- do.call(rbind, results_list) %>% 
  as.data.frame(stringsAsFactors = FALSE)

numeric_cols <- setdiff(names(results_df), "Metric")
results_df[numeric_cols] <- lapply(results_df[numeric_cols], as.numeric)

print(results_df)

write.csv(results_df, 
          file = "/path/to/save/BlandAltman_summary_stats.csv", 
          row.names = FALSE)
