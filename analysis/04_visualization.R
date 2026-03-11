# 04_visualization.R
# Goal: Generate key plots for the analysis
# Updates: Added Sample Distance Heatmap and ensured use of VST.

library(DESeq2)
library(tidyverse)
library(pheatmap)
library(EnhancedVolcano)
library(RColorBrewer)

# 1. Load results
if (!file.exists("./analysis/.RData/02_deseq_results.RData")) {
  stop("Input file ./analysis/.RData/02_deseq_results.RData not found. Run script 02 first.")
}
load("./analysis/.RData/02_deseq_results.RData")

# 2. Variance Stabilizing Transformation (VST)
# VST is a normalization method that stabilizes variance across the mean, 
# making it suitable for clustering and PCA (homoscedasticity).
vsd <- vst(dds, blind = FALSE)

# 3. PCA Plot
pca_plot <- plotPCA(vsd, intgroup = "condition") + 
  theme_minimal() + 
  ggtitle("PCA - Sample Similarity")
ggsave("./results/figures/04_pca_plot.png", pca_plot)

# 4. Sample-to-Sample Distance Heatmap
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste(vsd$condition, rownames(colData(vsd)), sep="-")
colnames(sampleDistMatrix) <- NULL
colors <- colorRampPalette( rev(brewer.pal(9, "Blues")) )(255)

pheatmap(sampleDistMatrix,
         clustering_distance_rows = sampleDists,
         clustering_distance_cols = sampleDists,
         col = colors,
         main = "Sample-to-Sample Distance",
         filename = "./results/figures/04_sample_dist_heatmap.png")

# 5. Volcano Plot
volcano_plot <- EnhancedVolcano(res_shrunk,
                                lab = rownames(res_shrunk),
                                x = 'log2FoldChange',
                                y = 'padj',
                                title = 'Differential Expression: Treatment vs Control',
                                pCutoff = 0.05,
                                FCcutoff = 1.0,
                                subtitle = "Volcano Plot (Shrunk LFC)")
ggsave("./results/figures/04_volcano_plot.png", volcano_plot)

# 6. Heatmap of top 30 significant genes
top30 <- head(order(res_shrunk$padj), 30)
mat <- assay(vsd)[top30, ]
mat <- mat - rowMeans(mat) # Center the rows (z-score like)
pheatmap(mat, 
         annotation_col = as.data.frame(colData(dds)[, "condition", drop=F]),
         main = "Top 30 DEGs Heatmap (VST)",
         filename = "./results/figures/04_top30_heatmap.png")

message("Visualizations generated in ./results/figures/")