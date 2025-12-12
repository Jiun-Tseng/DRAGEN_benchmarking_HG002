# SUMMARY
# This script loads multiple TSV benchmarking files, filters by variant type (SNP / INDEL),
# extracts sample identifiers, filters to Whole Genome samples, organizes coverage labels,
# reshapes metrics into long format, generates SNP + INDEL plots across DRAGEN experiments,
# and saves individual + combined figures.

# Load Libraries

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(patchwork)
library(stringr)

# Folder with input TSV files

folder_path <- "/Users/jtseng/Documents/TAG/2325/simplebenchmarking/tag_2325/hg001_30x"
file_list <- list.files(path = folder_path, pattern = "\\.tsv$", full.names = TRUE)

# Initialize empty lists

snp_rows_list <- list()
indel_rows_list <- list()

# LOOP: Read, filter, and extract sample name
for (file in file_list) {
  df <- read.delim(file, stringsAsFactors = FALSE)

  if ("Type" %in% colnames(df)) {
    # Extract sample ID like "SM-G947H" from Query_Name
    df <- df %>%
      mutate(Query_Sample = str_extract(Query_Name, "SM-[^_]+"))

    # OPTIONAL: filter for Whole Genome type only
    if ("Library_Type" %in% colnames(df)) {
      df <- df %>% filter(Library_Type == "Whole Genome")
    }

    # Split SNP vs INDEL
    snp_rows_list[[length(snp_rows_list) + 1]] <- df %>% filter(Type == "SNP")
    indel_rows_list[[length(indel_rows_list) + 1]] <- df %>% filter(Type == "INDEL")
  }
}

# Combine rows

HG130_SNP <- bind_rows(snp_rows_list)
HG130_INDEL <- bind_rows(indel_rows_list)

# Add coverage labels

Coverage_arrange <- function(df) {
  df %>%
    mutate(Coverage = case_when(
      Query_Name == "2148423243" ~ "34.6X",
      Query_Name == "2148423315" ~ "34.3X",
      Query_Name == "2148423316" ~ "37.2X",
      Query_Name == "2148423322" ~ "32.3X",
      TRUE ~ NA_character_
    )) %>%
    arrange(Interval)
}

HG130_SNP <- Coverage_arrange(HG130_SNP)
HG130_INDEL <- Coverage_arrange(HG130_INDEL)

# Reshape into long format

HG130_SNP_long <- HG130_SNP %>%
  pivot_longer(cols = c(Precision, Recall, F1_Score),
               names_to = "Metric", values_to = "Value") %>%
  mutate(Metric = recode(Metric, "F1_Score" = "F1 Score"))

HG130_INDEL_long <- HG130_INDEL %>%
  pivot_longer(cols = c(Precision, Recall, F1_Score),
               names_to = "Metric", values_to = "Value") %>%
  mutate(Metric = recode(Metric, "F1_Score" = "F1 Score"))

HG130_SNP_long$Interval <- factor(HG130_SNP_long$Interval)
HG130_INDEL_long$Interval <- factor(HG130_INDEL_long$Interval)

# PLOTS

HG130_SNP_plot <- ggplot(HG130_SNP_long, aes(x = Interval, y = Value, color = Experiment)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  facet_wrap(~ Metric, ncol = 1, scales = "free_y") +
  scale_color_brewer(palette = "Set2") +
  ggtitle("HG002 SNP Metrics Across All Intervals") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(face = "bold"))

HG130_INDEL_plot <- ggplot(HG130_INDEL_long, aes(x = Interval, y = Value, color = Experiment)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  facet_wrap(~ Metric, ncol = 1, scales = "free_y") +
  scale_color_brewer(palette = "Set2") +
  ggtitle("HG002 INDEL Metrics Across All Intervals") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(face = "bold"))

# Combined Plot
combined_plot <- (HG130_SNP_plot | HG130_INDEL_plot) +
  plot_layout(guides = "collect") +
  plot_annotation(title = "HG002 SNP & INDEL Metrics Across All Intervals",
                  caption = "Combined benchmarking output") &
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        strip.text = element_text(face = "bold"))

# Save outputs
output_dir <- "/Users/jtseng/Documents/TAG/2325/simplebenchmarking/tag_2325/SItables/"
plots <- list(HG130_SNP_plot, HG130_INDEL_plot, combined_plot)
plot_names <- c("HG00130X_SNP_plot", "HG00130X_INDEL_plot", "HG00130X_combined")

for (i in seq_along(plots)) {
  ggsave(paste0(output_dir, plot_names[i], ".png"),
         plot = plots[[i]], width = 10, height = 6, units = "in")
}
