# 03_enrichment.R
# Goal: Functional enrichment analysis (ORA & GSEA)
# Updates: Added GSEA as per comprehensive workflow notes.

library(clusterProfiler)
library(org.Sc.sgd.db) 
library(tidyverse)
library(enrichplot)

# 1. Load results from DESeq2
if (!file.exists("./analysis/.RData/02_deseq_results.RData")) {
  stop("Input file ./analysis/.RData/02_deseq_results.RData not found. Run script 02 first.")
}
load("./analysis/.RData/02_deseq_results.RData")

# --- Part A: Over-Representation Analysis (ORA) ---
# Filter Significant DEGs
sig_genes <- as.data.frame(res_shrunk) %>%
  filter(padj < 0.05 & abs(log2FoldChange) > 1) %>%
  rownames()

if (length(sig_genes) > 0) {
    # GO Enrichment (BP)
    go_res <- enrichGO(gene          = sig_genes,
                       OrgDb         = org.Sc.sgd.db,
                       keyType       = "ORF", 
                       ont           = "BP", 
                       pAdjustMethod = "BH",
                       pvalueCutoff  = 0.01,
                       qvalueCutoff  = 0.05)
    
    write.csv(as.data.frame(go_res), 
              file = "./results/tables/03_go_enrichment_results.csv")
    
    # Dotplot for ORA
    if (nrow(go_res) > 0) {
        dp <- dotplot(go_res, showCategory=20) + ggtitle("GO Enrichment (ORA)")
        ggsave("./results/figures/03_ora_dotplot.png", dp, width = 8, height = 8)
    }
} else {
    message("No significant genes for ORA.")
    go_res <- NULL
}

# --- Part B: Gene Set Enrichment Analysis (GSEA) ---
# GSEA uses a RANKED list of ALL genes, not just DEGs.
# Ranking metric: Stat (Wald statistic) is robust. Alternatively: sign(LFC) * -log10(pvalue).
res_df <- as.data.frame(res_shrunk) %>% 
  rownames_to_column("GeneID") %>%
  filter(!is.na(padj)) %>%  # Remove NAs
  arrange(desc(log2FoldChange)) # Rank by LFC (or stat)

# Create ranked vector
gene_list <- res_df$log2FoldChange
names(gene_list) <- res_df$GeneID

# Run gseGO
# Note: minGSSize might need adjustment for small genomes/sets
gse_res <- gseGO(geneList     = gene_list,
                 OrgDb        = org.Sc.sgd.db,
                 keyType      = "ORF",
                 ont          = "BP",
                 minGSSize    = 10,
                 maxGSSize    = 500,
                 pvalueCutoff = 0.05,
                 verbose      = FALSE,
                 seed         = TRUE) # Reproducibility

if (!is.null(gse_res) && nrow(gse_res) > 0) {
    write.csv(as.data.frame(gse_res), 
              file = "./results/tables/03_gsea_results.csv")
    
    # Visualizations for GSEA
    # 1. Dotplot
    dp_gsea <- dotplot(gse_res, showCategory=10, split=".sign") + facet_grid(.~.sign) + ggtitle("GSEA (GO:BP)")
    ggsave("./results/figures/03_gsea_dotplot.png", dp_gsea, width = 10, height = 8)
    
    # 2. Ridgeplot (Distribution of fold changes in enriched terms)
    rp_gsea <- ridgeplot(gse_res, showCategory=10) + ggtitle("GSEA Ridgeplot")
    ggsave("./results/figures/03_gsea_ridgeplot.png", rp_gsea, width = 8, height = 8)
} else {
    message("No significant GSEA terms found.")
}

save(go_res, gse_res, file = "./analysis/.RData/03_enrichment_results.RData")

message("Enrichment analysis (ORA & GSEA) complete.")
