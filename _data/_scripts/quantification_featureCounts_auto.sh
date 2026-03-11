#!/bin/bash

# Initialize Conda
# Adjust path if necessary for your system
source /home/mashxp/miniconda/etc/profile.d/conda.sh
conda activate yeast_rnaseq

# Define directories relative to the script location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
DATA_DIR=$(dirname "$SCRIPT_DIR")

BAM_DIR="$DATA_DIR/bam"
GTF_FILE="$DATA_DIR/ensembl/Saccharomyces_cerevisiae.R64-1-1.62.gtf"
COUNTS_DIR="$DATA_DIR/counts"
GENE_OUTPUT="$COUNTS_DIR/gene_counts.txt"
BIOTYPE_OUTPUT="$COUNTS_DIR/biotype_counts.txt"

# Create output directory
mkdir -p "$COUNTS_DIR"

# Check for BAM files
files=("$BAM_DIR"/*_sorted.bam)
if [ ${#files[@]} -eq 0 ]; then
    echo "No BAM files found in $BAM_DIR"
    exit 1
fi

echo "Starting Quantification with featureCounts..."
echo "GTF: $GTF_FILE"

# ---------------------------------------------------------
# 1. Gene Counts (for Differential Expression)
# ---------------------------------------------------------
echo "-----------------------------------------------------"
echo "1. Counting Reads per Gene (ID)..."
echo "Output: $GENE_OUTPUT"
featureCounts -T 4 -t exon -g gene_id -a "$GTF_FILE" -o "$GENE_OUTPUT" "${files[@]}"

# ---------------------------------------------------------
# 2. Biotype Counts (for QC)
# ---------------------------------------------------------
echo "-----------------------------------------------------"
echo "2. Counting Reads per Biotype (QC)..."
echo "Output: $BIOTYPE_OUTPUT"
featureCounts -T 4 -t exon -g gene_biotype -a "$GTF_FILE" -o "$BIOTYPE_OUTPUT" "${files[@]}"

# Summary
echo "-----------------------------------------------------"
echo "Quantification complete."
echo "Gene Counts: $GENE_OUTPUT"
echo "Biotype Counts: $BIOTYPE_OUTPUT"