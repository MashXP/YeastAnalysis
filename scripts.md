# STAR Alignment Organization Script.
```bash
for file in ../fastq/*.fastq
do
    # Get the sample name (removes .fastq extension)
    sample_name=$(basename "$file" .fastq)
    
    echo "Processing sample: $sample_name"
    
    # Create the folder
    mkdir -p "../STAR_aligned_output/$sample_name"
    
    # Run STAR with the combined Directory + Filename prefix
    STAR --genomeDir ../ensembl/yeast_index \
         --readFilesIn "$file" \
         --outFileNamePrefix "../STAR_aligned_output/$sample_name/${sample_name}_"
done
```

# GTF To BED12 Script.
```python
import sys

# Usage: python gtf2bed.py input.gtf > output.bed
# A simple script to convert GTF to BED12 for RSeQC

def parse_gtf(gtf_file):
    transcripts = {}
    
    with open(gtf_file, 'r') as f:
        for line in f:
            if line.startswith('#'): continue
            parts = line.strip().split('\t')
            if len(parts) < 9: continue
            if parts[2] != 'exon': continue
            
            chrom = parts[0]
            start = int(parts[3]) - 1 # GTF is 1-based, BED is 0-based
            end = int(parts[4])
            strand = parts[6]
            
            # Extract transcript_id
            attr_parts = parts[8].split(';')
            transcript_id = None
            for attr in attr_parts:
                if 'transcript_id' in attr:
                    transcript_id = attr.split('"')[1]
                    break
            
            if transcript_id:
                if transcript_id not in transcripts:
                    transcripts[transcript_id] = []
                transcripts[transcript_id].append((chrom, start, end, strand))

    # Write BED12
    for tid, exons in transcripts.items():
        exons.sort() # Sort by start position
        chrom = exons[0][0]
        strand = exons[0][3]
        tx_start = exons[0][1]
        tx_end = exons[-1][2]
        
        block_sizes = []
        block_starts = []
        
        for exon in exons:
            block_sizes.append(str(exon[2] - exon[1]))
            block_starts.append(str(exon[1] - tx_start))
            
        print(f"{chrom}\t{tx_start}\t{tx_end}\t{tid}\t0\t{strand}\t{tx_start}\t{tx_end}\t0\t{len(exons)}\t{','.join(block_sizes)},\t{','.join(block_starts)},")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python gtf2bed.py input.gtf")
    else:
        parse_gtf(sys.argv[1])

```

# RSeQC Automation Script.
```bash
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
```

# featureCounts Quantification Script
```bash
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
```

# Biotype to MultiQC Conversion Script
```python
import pandas as pd
import sys
import os

def parse_featurecounts(input_file, output_file):
    """
    Parses a featureCounts output file (biotype counts) and formats it for MultiQC.
    """
    # Read the featureCounts output, skipping the header comments
    df = pd.read_csv(input_file, sep="\t", comment="#")
    
    # The first column is the Geneid (or Biotype in our case)
    # The columns from index 6 onwards are the sample counts
    # We want to aggregate counts by Biotype
    
    # Check if 'Geneid' is the column name (standard featureCounts output)
    if 'Geneid' not in df.columns:
        print(f"Error: 'Geneid' column not found in {input_file}")
        return

    # Set Geneid (Biotype) as index
    df = df.set_index('Geneid')
    
    # Select only the count columns (usually start from column 6, after Length)
    # Column names are usually paths like ".../bam/sample.bam" -> we need to clean them
    count_cols = df.columns[5:] 
    
    # Create a new DataFrame for MultiQC
    mqc_df = df[count_cols].copy()
    
    # Clean up sample names in columns
    mqc_df.columns = [os.path.basename(c).replace("_sorted.bam", "") for c in mqc_df.columns]
    
    # Transpose so samples are rows and biotypes are columns (MultiQC format)
    mqc_df = mqc_df.transpose()
    
    # Calculate percentages (optional, but MultiQC handles raw counts well)
    # mqc_df = mqc_df.div(mqc_df.sum(axis=1), axis=0) * 100
    
    # Save to file with MultiQC custom content header
    with open(output_file, 'w') as f:
        f.write("# id: 'biotype_counts'\n")
        f.write("# section_name: 'Biotype Counts'\n")
        f.write("# description: 'Reads mapped to different gene biotypes (e.g. protein_coding, rRNA).'\n")
        f.write("# plot_type: 'bargraph'\n")
        f.write("# pconfig:\n")
        f.write("#    id: 'biotype_counts_plot'\n")
        f.write("#    title: 'Biotype Distribution'\n")
        f.write("#    ylab: 'Read Counts'\n")
        f.write("#    cpswitch_counts_label: 'Number of Reads'\n")
        f.write(mqc_df.to_csv(sep="\t", index=True, index_label="Sample"))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python biotype_to_multiqc.py input_counts.txt output_mqc.txt")
        sys.exit(1)
        
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    parse_featurecounts(input_path, output_path)
    print(f"Generated MultiQC custom content: {output_path}")
```


