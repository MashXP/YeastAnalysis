# 02_deseq2_dge.R
# Goal: Run Differential Gene Expression analysis with DESeq2
# Updates: Added explicit normalization check and MA plots per user request.

library(DESeq2)
library(tidyverse)
library(ggplot2)

# Ensure output directories exist
dir.create("./results/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("./results/tables", showWarnings = FALSE, recursive = TRUE)

# 1. Load data from previous step
if (!file.exists("./analysis/.RData/01_processed_counts.RData")) {
  stop("Input file ./analysis/.RData/01_processed_counts.RData not found. Run script 01 first.")
}
load("./analysis/.RData/01_processed_counts.RData")

# 2. Construct DESeqDataSet
# Ensure the reference level for condition is set to 'control'
col_data$condition <- relevel(col_data$condition, ref = "control")

dds <- DESeqDataSetFromMatrix(countData = counts_filtered,
                              colData = col_data,
                              design = ~ condition)

# 3. Normalization (Size Factors) & QC
# Explicitly estimate size factors to show normalization
dds <- estimateSizeFactors(dds)
normalized_counts <- counts(dds, normalized=TRUE)
raw_counts <- counts(dds, normalized=FALSE)

# QC Plot: Raw vs Normalized Count Distribution
# Transform for plotting (log2 + 1)
df_raw <- as.data.frame(raw_counts) %>% 
  pivot_longer(everything(), names_to = "Sample", values_to = "Count") %>%
  mutate(Type = "Raw")

df_norm <- as.data.frame(normalized_counts) %>% 
  pivot_longer(everything(), names_to = "Sample", values_to = "Count") %>%
  mutate(Type = "Normalized")

df_qc <- bind_rows(df_raw, df_norm)

p_norm <- ggplot(df_qc, aes(x = Sample, y = log2(Count + 1), fill = Type)) +
  geom_boxplot() +
  facet_wrap(~Type, scales = "free") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Normalization Check: Raw vs Normalized Counts")

ggsave("./results/figures/02_normalization_check.png", p_norm, width = 10, height = 6)
message("Normalization check plot saved to ./results/figures/02_normalization_check.png")

# 4. Run DESeq (Differential Expression Analysis)
# This steps includes:
# - Estimation of size factors (already done, but DESeq ensures it)
# - Estimation of dispersion
# - Negative Binomial GLM fitting
# - Wald statistics
dds <- DESeq(dds)

# 5. Extract results
# This compares 'treatment' against 'control'
res <- results(dds, contrast = c("condition", "treatment", "control"))

# 6. LFC Shrinkage & MA Plot
# Shrinkage handles low-count genes to prevent exaggerated Fold Changes.
# 'apeglm' is the recommended method.
res_shrunk <- lfcShrink(dds, coef = "condition_treatment_vs_control", type = "apeglm")

# MA Plot (Before Shrinkage)
png("./results/figures/02_ma_plot_raw.png", width = 800, height = 600)
plotMA(res, ylim=c(-5,5), main="MA Plot (Raw LFC)")
dev.off()

# MA Plot (After Shrinkage)
png("./results/figures/02_ma_plot_shrunk.png", width = 800, height = 600)
plotMA(res_shrunk, ylim=c(-5,5), main="MA Plot (Shrunk LFC)")
dev.off()

# 7. Save results
write.csv(as.data.frame(res_shrunk), 
          file = "./results/tables/02_dge_results_shrunk.csv")

# Save dds object for downstream use
save(dds, res, res_shrunk, normalized_counts, file = "./analysis/.RData/02_deseq_results.RData")

message("DGE analysis complete. Results saved to ./results/tables/02_dge_results_shrunk.csv")
