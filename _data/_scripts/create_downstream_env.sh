#!/bin/bash
# Create environment for downstream RNA-seq analysis (DGE, Visualization)

mamba create -n yeast_downstream -y -c bioconda -c conda-forge \
    r-base=4.4 \
    bioconductor-deseq2 \
    bioconductor-clusterprofiler \
    bioconductor-enhancedvolcano \
    bioconductor-org.sc.sgd.db \
    r-tidyverse \
    r-pheatmap \
    r-ggridges \
    bioconductor-apeglm
