#!/bin/bash

# Initialize Conda
# Adjust path if necessary for your system
source /home/mashxp/miniconda/etc/profile.d/conda.sh
conda activate yeast_rnaseq

# Define directories relative to the script location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
DATA_DIR=$(dirname "$SCRIPT_DIR")

BED_FILE="$DATA_DIR/ensembl/Saccharomyces_cerevisiae.R64-1-1.62.bed"
BAM_DIR="$DATA_DIR/bam"
RSEQC_DIR="$DATA_DIR/rseqc"

# Check if BED file exists
if [ ! -f "$BED_FILE" ]; then
    echo "Error: BED file not found at $BED_FILE"
    exit 1
fi

# Loop through sorted BAM files
for bam_file in "$BAM_DIR"/*_sorted.bam; do
    if [ ! -e "$bam_file" ]; then
        echo "No sorted BAM files found in $BAM_DIR"
        break
    fi

    filename=$(basename "$bam_file")
    # Remove _sorted.bam suffix to get sample name (e.g. ERR458497)
    sample_name="${filename%_sorted.bam}"
    
    echo "Processing sample: $sample_name"
    
    # Define Sample Directory
    SAMPLE_DIR="$RSEQC_DIR/$sample_name"
    mkdir -p "$SAMPLE_DIR"

    # ---------------------------------------------------------
    # 1. Gene Body Coverage
    # ---------------------------------------------------------
    gb_out_dir="$SAMPLE_DIR/geneBody_coverage"
    mkdir -p "$gb_out_dir"
    gb_prefix="${gb_out_dir}/${sample_name}"
    
    if [ -f "${gb_prefix}.geneBodyCoverage.txt" ]; then
        echo "  [Skipping] Gene Body Coverage for $sample_name (Output exists)"
    else
        echo "  [Running] Gene Body Coverage for $sample_name..."
        geneBody_coverage.py -i "$bam_file" -r "$BED_FILE" -o "$gb_prefix"
    fi

    # ---------------------------------------------------------
    # 2. Junction Annotation
    # ---------------------------------------------------------
    ja_out_dir="$SAMPLE_DIR/junction_annotation"
    mkdir -p "$ja_out_dir"
    ja_prefix="${ja_out_dir}/${sample_name}"
    
    if [ -f "${ja_prefix}.junction.xls" ]; then
        echo "  [Skipping] Junction Annotation for $sample_name (Output exists)"
    else
        echo "  [Running] Junction Annotation for $sample_name..."
        junction_annotation.py -i "$bam_file" -r "$BED_FILE" -o "$ja_prefix" 2> "${ja_prefix}.log"
    fi

    # ---------------------------------------------------------
    # 3. Read Distribution
    # ---------------------------------------------------------
    rd_out_dir="$SAMPLE_DIR/read_distribution"
    mkdir -p "$rd_out_dir"
    rd_output="${rd_out_dir}/${sample_name}.read_distribution.txt"
    
    if [ -f "$rd_output" ]; then
        echo "  [Skipping] Read Distribution for $sample_name (Output exists)"
    else
        echo "  [Running] Read Distribution for $sample_name..."
        read_distribution.py -i "$bam_file" -r "$BED_FILE" > "$rd_output"
    fi
    
    echo "Done with $sample_name"
done

echo "All samples processed."
