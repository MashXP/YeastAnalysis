#!/bin/bash
# Create environment for upstream RNA-seq analysis (Quality Control, Alignment, Quantification)
# Based on tools used in _main_OverviewYeast.md

mamba create -n yeast_upstream -y -c bioconda -c conda-forge \
    sra-tools=3 \
    fastqc \
    multiqc \
    star \
    rseqc \
    subread
