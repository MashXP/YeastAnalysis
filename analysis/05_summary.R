# 05_summary.R
# Goal: Generate comprehensive Markdown summary reports for analysis steps 01-04
# Usage: Run this script from the 'exercise' directory
# Example: Rscript analysis/05_summary.R

suppressPackageStartupMessages({
    library(tidyverse)
    library(DESeq2)
    library(clusterProfiler)
    library(org.Sc.sgd.db)
})

# Create output directory
summary_dir <- "./results/summary"
if (!dir.exists(summary_dir)) {
    dir.create(summary_dir, recursive = TRUE)
    message("Created summary directory: ", summary_dir)
}

message("Generating summaries...")

# --- Summary 01: Data Prep ---
rdata_01 <- "./analysis/.RData/01_processed_counts.RData"
if (file.exists(rdata_01)) {
    load(rdata_01)
    
    summary_01 <- c(
        "# 01 Data Prep Summary",
        "",
        paste("- **Total Samples:**", ncol(counts_filtered)),
        paste("- **Conditions:**", paste(levels(col_data$condition), collapse = ", ")),
        paste("- **Genes (Filtered):**", nrow(counts_filtered)),
        "",
        "## Sample Metadata",
        "| Sample | Condition |",
        "| :--- | :--- |",
        paste("|", rownames(col_data), "|", col_data$condition, "|")
    )
    
    writeLines(summary_01, file.path(summary_dir, "01_data_prep_summary.md"))
    message("  [v] 01_data_prep_summary.md")
}

# --- Summary 02: DGE & Normalization ---
rdata_02 <- "./analysis/.RData/02_deseq_results.RData"
if (file.exists(rdata_02)) {
    load(rdata_02)
    
    # Process results for summary
    res_df <- as.data.frame(res_shrunk) %>% 
        rownames_to_column("GeneID")
    
    # Thresholds
    padj_th <- 0.05
    lfc_th <- 1.0
    
    sig_genes <- res_df %>% filter(padj < padj_th & abs(log2FoldChange) > lfc_th)
    up_genes <- sig_genes %>% filter(log2FoldChange > 0)
    down_genes <- sig_genes %>% filter(log2FoldChange < 0)
    
    top_up <- up_genes %>% arrange(desc(log2FoldChange)) %>% head(5)
    top_down <- down_genes %>% arrange(log2FoldChange) %>% head(5)
    
    fmt_table <- function(df) {
        if (nrow(df) == 0) return(character(0))
        paste("|", df$GeneID, "|", round(df$log2FoldChange, 2), "|", format(df$padj, scientific=TRUE, digits=3), "|")
    }
    
    summary_02 <- c(
        "# 02 DGE & Normalization Summary",
        "",
        "## Normalization",
        "Normalization was performed using the **Median of Ratios** method (DESeq2).",
        "![Normalization Check](../figures/02_normalization_check.png)",
        "",
        "## Differential Expression Overview",
        paste("- **Significant DEGs** (padj <", padj_th, ", |LFC| >", lfc_th, "):", nrow(sig_genes)),
        paste("  - **Up-regulated:**", nrow(up_genes)),
        paste("  - **Down-regulated:**", nrow(down_genes)),
        "",
        "## MA Plots",
        "### Before LFC Shrinkage",
        "![MA Raw](../figures/02_ma_plot_raw.png)",
        "### After LFC Shrinkage (apeglm)",
        "![MA Shrunk](../figures/02_ma_plot_shrunk.png)",
        "",
        "## Top 5 Up-regulated Genes",
        "| GeneID | Log2FC | padj |",
        "| :--- | :--- | :--- |",
        fmt_table(top_up),
        "",
        "## Top 5 Down-regulated Genes",
        "| GeneID | Log2FC | padj |",
        "| :--- | :--- | :--- |",
        fmt_table(top_down)
    )
    
    writeLines(summary_02, file.path(summary_dir, "02_dge_summary.md"))
    message("  [v] 02_dge_summary.md")
}

# --- Summary 03: Enrichment (ORA & GSEA) ---
rdata_03 <- "./analysis/.RData/03_enrichment_results.RData"
if (file.exists(rdata_03)) {
    load(rdata_03)
    
    # ORA Summary
    go_df <- as.data.frame(go_res)
    ora_section <- if (nrow(go_df) > 0) {
        top_go <- go_df %>% arrange(p.adjust) %>% head(5)
        desc <- top_go$Description
        desc[nchar(desc) > 50] <- paste0(substr(desc[nchar(desc) > 50], 1, 47), "...")
        c(
            "## Over-Representation Analysis (ORA)",
            paste("- **Significant GO Terms (BP):**", nrow(go_df)),
            "![ORA Dotplot](../figures/03_ora_dotplot.png)",
            "",
            "| ID | Description | p.adjust | Count |",
            "| :--- | :--- | :--- | :--- |",
            paste("|", top_go$ID, "|", desc, "|", format(top_go$p.adjust, scientific=TRUE, digits=3), "|", top_go$Count, "|")
        )
    } else { "## ORA: No significant terms found." }

    # GSEA Summary
    gse_df <- as.data.frame(gse_res)
    gsea_section <- if (nrow(gse_df) > 0) {
        top_gse <- gse_df %>% arrange(p.adjust) %>% head(5)
        desc_gse <- top_gse$Description
        desc_gse[nchar(desc_gse) > 50] <- paste0(substr(desc_gse[nchar(desc_gse) > 50], 1, 47), "...")
        c(
            "",
            "## Gene Set Enrichment Analysis (GSEA)",
            paste("- **Significant Enriched Terms:**", nrow(gse_df)),
            "![GSEA Dotplot](../figures/03_gsea_dotplot.png)",
            "![GSEA Ridgeplot](../figures/03_gsea_ridgeplot.png)",
            "",
            "| ID | Description | NES | p.adjust |",
            "| :--- | :--- | :--- | :--- |",
            paste("|", top_gse$ID, "|", desc_gse, "|", round(top_gse$NES, 2), "|", format(top_gse$p.adjust, scientific=TRUE, digits=3), "|")
        )
    } else { "## GSEA: No significant terms found." }
    
    summary_03 <- c("# 03 Enrichment Summary", "", ora_section, gsea_section)
    writeLines(summary_03, file.path(summary_dir, "03_enrichment_summary.md"))
    message("  [v] 03_enrichment_summary.md")
}

# --- Summary 04: Visualizations ---
summary_04 <- c(
    "# 04 Visualization Summary",
    "",
    "## Exploratory Analysis",
    "### PCA Plot (VST Transformed)",
    "![PCA](../figures/04_pca_plot.png)",
    "### Sample Distance Heatmap",
    "![Dist Heatmap](../figures/04_sample_dist_heatmap.png)",
    "",
    "## Gene-level Analysis",
    "### Volcano Plot",
    "![Volcano](../figures/04_volcano_plot.png)",
    "### Top 30 DEGs Heatmap",
    "![Top30 Heatmap](../figures/04_top30_heatmap.png)"
)
writeLines(summary_04, file.path(summary_dir, "04_visualization_summary.md"))
message("  [v] 04_visualization_summary.md")

message("Summary generation complete.")
