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
├── _data/                               # Raw, intermediate, and QC data (Git ignored)
│   ├── _scripts/                        # Upstream automation scripts
│   │   ├── biotype_to_multiqc.py         # Converts featureCounts output for MultiQC
│   │   ├── create_downstream_env.sh      # Sets up R/Bioconductor environment
│   │   ├── create_upstream_env.sh        # Sets up Conda environment for QC/Alignment
│   │   ├── gtf2bed.py                    # Converts GTF to BED12 for RSeQC
│   │   ├── quantification_featureCounts_auto.sh # Automates read counting
│   │   ├── rseqc_analysis_auto.sh        # Automates RSeQC suite
│   │   ├── SAMtoBAM.sh                   # Converts/sorts SAM to BAM
│   │   ├── STAR_alignment_auto.sh        # Automates STAR mapping
│   │   └── vsc_r_setup.sh                # Environment setup for VSC
│   ├── bam/                             # Sorted and indexed BAM files
│   │   ├── ERR458497_sorted.bam(.bai) ... ERR458502_sorted.bam(.bai)
│   ├── counts/                          # Raw count matrices
│   │   ├── gene_counts.txt              # Primary matrix for DGE
│   │   ├── biotype_counts.txt           # Secondary matrix for biotype QC
│   │   └── gene_counts.txt.summary      # featureCounts mapping summary
│   ├── ensembl/                         # Reference genome and annotation
│   │   ├── Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa
│   │   ├── Saccharomyces_cerevisiae.R64-1-1.62.gtf
│   │   ├── Saccharomyces_cerevisiae.R64-1-1.62.bed (BED12 version)
│   │   └── yeast_index/                 # STAR Index (Genome, SA, SAindex, etc.)
│   ├── fastq/                           # Decompressed reads (ERR458497.fastq ...)
│   ├── fastqc/                          # FastQC HTML/ZIP reports for each sample
│   ├── multiqc_report_data/             # Aggregated MultiQC statistics
│   ├── multiqc_report.html              # Final Master MultiQC report
│   ├── rseqc/                           # RSeQC metrics (geneBodyCoverage, etc.)
│   └── STAR_aligned_output/             # STAR log files and splice junction tables
├── analysis/                            # Downstream R analysis pipeline
│   ├── .RData/                          # Saved R analysis objects
│   │   ├── 01_processed_counts.RData
│   │   ├── 02_deseq_results.RData
│   │   └── 03_enrichment_results.RData
│   ├── 00_lib_install.R                 # Dependency installer
│   ├── 01_data_prep.R                   # Data cleaning/filtering
│   ├── 02_deseq2_dge.R                  # Differential expression
│   ├── 03_enrichment.R                  # Functional enrichment
│   ├── 04_visualization.R               # Figure generation
│   └── 05_summary.R                     # Results aggregation
├── results/                             # Final Analysis Outputs
│   ├── figures/                         # PCA, Volcano, MA, Heatmap plots
│   ├── summary/                         # Step-by-step markdown summaries
│   └── tables/                          # Exported CSVs (DGE, GO, GSEA results)
├── _main_OverviewYeast.md               # Initial project notes and CLI logs
├── multiqc_fastqc.md                    # Detailed FastQC summary and interpretation
├── multiqc_rseqc.md                    # Detailed RSeQC summary and interpretation
├── multiqc_STAR.md                     # Detailed STAR alignment summary
├── scripts.md                           # Documentation for automation scripts
├── .Rprofile                            # R project-specific configuration
└── README.md                            # Project documentation and entry point
```

## Large Data Policy
To keep the repository lightweight, heavy bioinformatics data files are excluded from version control via `.gitignore`.

### Ignored Files & Regeneration
- **Raw Data (`raw.sra/`, `fastq/`)**: Original `.sra` and `.fastq` files (PRJEB5348).
- **Genome Index (`ensembl/yeast_index/`)**: STAR index files (`Genome`, `SA`, `SAindex`).
- **Alignments (`STAR_aligned_output/`, `bam/`)**: Intermediate `.sam` and final sorted `.bam`/`.bai` files.
    - *Regeneration*: BAM files can be recreated using `_data/_scripts/SAMtoBAM.sh`.

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
