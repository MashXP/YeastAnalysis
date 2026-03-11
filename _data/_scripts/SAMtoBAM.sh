#!/bin/bash

# Ensure the script operates relative to its own location
# This fixes issues where running the script from a different directory breaks relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define directories relative to the script path
INPUT_DIR="${SCRIPT_DIR}/../STAR_aligned_output"
OUTPUT_DIR="${SCRIPT_DIR}/../bam"

# Create the bam output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Enable nullglob so that if no matches are found, the loop doesn't run with the literal glob string
shopt -s nullglob

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory $INPUT_DIR not found."
    exit 1
fi

# Find sample directories
sample_dirs=("$INPUT_DIR"/ERR*)

if [ ${#sample_dirs[@]} -eq 0 ]; then
    echo "No sample directories found in $INPUT_DIR matching 'ERR*'"
    exit 1
fi

# Loop through every sample folder
for sample_dir in "${sample_dirs[@]}"
do
    # 1. Get the sample name (e.g., ERR458497) from the folder path
    sample_name=$(basename "$sample_dir")
    
    echo "Processing: $sample_name"
    
    # 2. Define our input (SAM) and output (BAM) filenames
    input_sam="${sample_dir}/${sample_name}_Aligned.out.sam"
    output_bam="${OUTPUT_DIR}/${sample_name}_sorted.bam"
    
    # Check if input SAM exists
    if [ ! -f "$input_sam" ]; then
        echo "  Warning: SAM file not found: $input_sam"
        continue
    fi

    # 3. Convert SAM to BAM and Sort (all in one step)
    # The -o flag specifies the output file
    echo "  Sorting and converting to BAM..."
    samtools sort -o "$output_bam" "$input_sam"
    
    if [ $? -ne 0 ]; then
        echo "  Error: samtools sort failed for $sample_name"
        continue
    fi

    # 4. Index the new BAM file (creates .bam.bai)
    echo "  Indexing BAM..."
    samtools index "$output_bam"
    
    # Optional: Delete the huge SAM file to save space
    # Uncomment the next line if you are sure!
    # rm "$input_sam"
    
    echo "Done with $sample_name!"
done
