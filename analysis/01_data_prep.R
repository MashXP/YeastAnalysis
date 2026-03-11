# 01_data_prep.R
# Goal: Load raw counts and prepare metadata for DESeq2

library(tidyverse)

# 1. Load Gene Counts
raw_counts <- read_delim("./_data/counts/gene_counts.txt", 
                         delim = "\t", skip = 1) %>%
  rename_with(~basename(.) %>% str_remove("_sorted.bam"), everything())

# Extract count matrix
counts_matrix <- raw_counts %>%
  select(Geneid, 7:last_col()) %>%
  column_to_rownames("Geneid")

# 2. Create colData (Metadata)
samples <- colnames(counts_matrix)
col_data <- data.frame(
  condition = factor(rep(c("control", "treatment"), each = 3)),
  row.names = samples
)

# 3. Pre-filtering
keep <- rowSums(counts_matrix >= 10) >= 3
counts_filtered <- counts_matrix[keep,]

# 4. Save processed objects
save(counts_filtered, col_data, file = "./analysis/.RData/01_processed_counts.RData")

print("Metadata (col_data) preview:")
print(col_data)
message("Data preparation complete.")
