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