# Yeast RNA-seq Analysis: *snf2* Mutant vs Wild Type

[![R version](https://img.shields.io/badge/R-%3E%3D4.0-blue.svg)](https://www.r-project.org/)
[![DESeq2](https://img.shields.io/badge/Bioconductor-DESeq2-green.svg)](https://bioconductor.org/packages/release/bioc/html/DESeq2.html)

This repository contains the downstream analysis pipeline for an RNA-seq experiment comparing *Saccharomyces cerevisiae* Wild Type (WT) and *snf2* mutant strains.

## Overview
The goal of this study is to identify differentially expressed genes (DEGs) and enriched biological pathways associated with the loss of the **Snf2** chromatin remodeling factor.

- **Project Start Date:** 2026-01-17
- **Organism:** *Saccharomyces cerevisiae*
- **Accession:** [PRJEB5348](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJEB5348)
- **Experimental Design:** 3 replicates of Wild Type vs. 3 replicates of *snf2* mutant.

## Analysis Pipeline

### 1. Upstream Processing (Summary)
The raw data was processed using standard bioinformatics tools:
- **Quality Control:** FastQC & MultiQC
- **Alignment:** STAR (indexed against R64-1-1 genome)
- **Post-Alignment QC:** RSeQC (mapping distribution, gene body coverage)
- **Quantification:** `featureCounts` (Subread)

### 2. Downstream Analysis (R)
Located in the `analysis/` directory, the pipeline follows these steps:
1. `01_data_prep.R`: Loads raw count matrices and prepares metadata.
2. `02_deseq2_dge.R`: Differential expression analysis using DESeq2 (Negative Binomial GLM).
3. `03_enrichment.R`: Functional enrichment via ORA (Over-Representation Analysis) and GSEA (Gene Set Enrichment Analysis).
4. `04_visualization.R`: Generation of PCA, Volcano, and Heatmap plots.
5. `05_summary.R`: Final aggregation of results and reporting.

## Project Structure
```text
YeastAnalysis/
├── analysis/                 # Downstream R analysis pipeline
│   ├── .RData/               # Saved intermediate analysis objects
│   │   ├── 01_processed_counts.RData
│   │   ├── 02_deseq_results.RData
│   │   └── 03_enrichment_results.RData
│   ├── 00_lib_install.R      # Dependency management script
│   ├── 01_data_prep.R        # Data loading and cleaning
│   ├── 02_deseq2_dge.R       # Differential Gene Expression analysis
│   ├── 03_enrichment.R       # GO and pathway enrichment analysis
│   ├── 04_visualization.R    # PCA, Heatmaps, and Volcano plots
│   └── 05_summary.R          # Markdown report generation script
├── multiqc_STAR.md           # MultiQC alignment summary
├── multiqc_fastqc.md         # MultiQC raw data quality summary
├── multiqc_rseqc.md          # MultiQC mapping and coverage summary
├── scripts.md                # Compilation of automation and helper scripts
├── _main_OverviewYeast.md    # Master lab notes, upstream processing & context
└── README.md                 # Project documentation and entry point
```

## Setup and Dependencies
To reproduce the analysis, ensure you have R installed. You can install all required CRAN and Bioconductor packages by running the provided installation script:

```r
source("analysis/00_lib_install.R")
```

The script handles the installation of:
- **CRAN:** `tidyverse`, `pheatmap`, `BiocManager`
- **Bioconductor:** `DESeq2`, `clusterProfiler`, `org.Sc.sgd.db`, `apeglm`, `EnhancedVolcano`

## Usage
The analysis is structured to be run sequentially from `01_data_prep.R` through `05_summary.R`. 
Pre-processed R objects are stored in `analysis/.RData/` to allow jumping into specific analysis steps without re-running the entire pipeline.

## Key Findings
Initial results from the *snf2* mutant vs. Wild Type comparison show significant transcriptomic shifts:

- **Total Significant DEGs:** 366 (padj < 0.05, |log2FC| > 1)
  - **Up-regulated:** 138 genes
  - **Down-regulated:** 228 genes
- **Top Enriched Pathways:** Oxoacid metabolic process, Organic acid metabolic process, and Ribosome biogenesis.

For a detailed breakdown, refer to the generated summaries in `results/summary/` (after running `analysis/05_summary.R`).

## TODO
- [ ] **Data Visualization:** Ensure all figures in `results/figures/` are correctly linked and documented.
- [ ] **Biological Interpretation:** Add context to the enriched pathways in a final discussion section.
