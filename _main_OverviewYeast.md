
# 0. Init - Create a conda env (2026-01-17)

```bash
conda create --name yeast_rnaseq python=3.10
conda activate yeast_rnaseq

# conda channels order is CRUCIAL! 
conda config --env --add channels bioconda
conda config --env --add channels conda-forge
conda config --env --set channel_priority strict

# install mamba for faster downloading
conda install -n base mamba
```

> [!tip]
> To verify channel orientation:
> ```bash
> conda config --show channels
> ```

# 1. Raw data
**Sequence Read Archive (SRA)**: raw sequencing data lib.

```bash
mamba install sra-tools=3 # To fix the versioning issue - Use mamba to bypass the load issue
```

> [!tip]
> To check for package:
> ```bash
> conda list
> ```

## SRA Run Selector
[Run Selector - NCBI](https://www.ncbi.nlm.nih.gov/Traces/study/) 
Search: `PRJEB5348`

## 6 targets. 🎯
**Wild Type (WT):**
1. `ERR458497`
2. `ERR458498`
3. `ERR458499`
**Mutant (_snf2_):**
4. `ERR458500`
5. `ERR458501` 
6. `ERR458502`

## Download the Data using `prefetch` (2026-01-18)

```bash
prefetch ERR458497 ERR458498 ERR458499 ERR458500 ERR458501 ERR458502

# dumping .fastq
fasterq-dump --progress ERR458497 ERR458498 ERR458499 ERR458500 ERR458501 ERR458502
```

Example:
```fastq
...
@ERR458497.1 DHKW5DQ1:219:D0PT7ACXX:5:1101:1484:2173 length=51
TTTGGGATTATAATGAGTGGCAGTTGACAGATTAAAATCACATGACCTAGA
+ERR458497.1 DHKW5DQ1:219:D0PT7ACXX:5:1101:1484:2173 length=51
CCCFFFFFHHHHHJJJJHIIJJJIIIIIJJGHIGJJJIGIIJJJJJJJJJJ
@ERR458497.2 DHKW5DQ1:219:D0PT7ACXX:5:1101:1675:2045 length=51
CAGCACGGTATGTTTTACTATACAAGGTTTAGTCCAAAGCAAGTCGAAATA
...

```

**Annotations**:
- @: read
- J: hi-qual
- c: lo-qual
- #, !: bad-qual

# 2. FastQC

## Installing
```bash
mamba install fastqc
```

## Run

```bash
fastqc *.fastq
```

### Optional: MultiQC 
Use `multiqc` for a comprehensive overview
```bash
mamba install multiqc
multiqc .
```

![[multiqc_fastqc]]

## Results
The read results are high quality enough to move to the next step. No need for further processing.

# 3. Alignment
![[08_upstream#Basic alignment]]

**Q:** Which aligner is better? Contiguous or Splice-Aware?
**A:**For DNA, contiguous. For RNA, splice-aware is **BETTER** ✅. Better intron interpretations.

**Q:** Does different tool produce different results?
**A:** Short: Yes, Long: Yes, but small and will not significantly effect DGEs and later steps performance.

## Tool: `STAR`

[EnsemblFungi - FTP Download](https://fungi.ensembl.org/info/data/ftp/index.html)

**Requirements:** 
- **The Reference Genome (`.fasta` or `.fa`)** - [Index of /pub/fungi/release-62/fasta/saccharomyces_cerevisiae/dna](http://ftp.ensemblgenomes.org/pub/fungi/release-62/fasta/saccharomyces_cerevisiae/dna/?C=N;O=A)

```bash
wget http://ftp.ensemblgenomes.org/pub/fungi/release-62/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
```
- **`dna`:** The standard, raw sequence (A, C, T, G). (Best for STAR) ✅
- **`dna_rm` (Repeat Masked):** All repetitive junk DNA is replaced with the letter "N". This "hard masking" hides information.
- **`dna_sm` (Soft Masked):** Repetitive DNA is written in lowercase (a, c, t, g).

- **The Gene Annotation (`.gtf`):** This stands for **Gene Transfer Format**. 	- [Index of /ensemblgenomes/pub/release-62/fungi/gtf/saccharomyces_cerevisiae](https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-62/fungi/gtf/saccharomyces_cerevisiae/)
```bash
wget https://ftp.ebi.ac.uk/ensemblgenomes/pub/release-62/fungi/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.62.gtf.gz
```

**Decompression:** `gzip --decompress .` 

### Building the Index
```bash
STAR --runMode genomeGenerate \
--genomeDir ./yeast_index \
--genomeFastaFiles ./Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa \
--sjdbGTFfile ./Saccharomyces_cerevisiae.R64-1-1.62.gtf \
--sjdbOverhang 50 \
--genomeSAindexNbases 10 
```
 -  `--sjdbOverhang 51` = length (.fastq) - 1
 - `--genomeSAindexNbases 10`: to prevent: # ERROR: !!!!! WARNING: --genomeSAindexNbases 14 is too large for the genome size=12157105, which may cause seg-fault at the mapping step. Re-run genome generation with recommended --genomeSAindexNbases 10

### Actual Alignment
Remember to check whether if your data is **SINGLE** or **PAIRED_END**!

**Run customized script:**[[scripts#STAR Alignment Organization Script.]]
**MultiQC:**
```bash
multiqc ./STAR_aligned_output
```
![[multiqc_STAR]]
## Tool: `RSeQC` (2026-01-19)
**Installation:**
```bash
mamba install rseqc
```

**Requirements:**
- `*.bam`
- `*.bed` : generated from existing `.gtf` using personal script
	- BED12 is **ABSOLUTELY needed!**
**Q:** Why BED12 but not other BED?
**A:** 
- **Regular BED (BED6):** It draws a single big box from the start of the gene to the end. It ignores introns. If you use this, RSeQC will think the introns are part of the gene and will report "zero coverage" for those areas, messing up your stats.
- **BED12:** It draws the **Exons only**. It tells RSeQC exactly where the reading frame is (the blocks) and where the introns are (the gaps).

[[scripts#GTF To BED12 Script.]]

After Obtaining the necessary files...

[[scripts#RSeQC Automation Script.]]

## MultiQC Aggregation

After running various QC tools, we aggregate everything into a final report.

**Q:** Should there be many MultiQC HTMLs or just one?
**A:** It is normal to have intermediate reports (FastQC, STAR, RSeQC) while building the pipeline, but a **single Master Report** is the standard best practice.

**Q:** Why is a single big Master Report recommended?
**A:** Correlation and convenience. You can compare metrics side-by-side (e.g., seeing if low STAR alignment rates correlate with poor FastQC quality) and have one holistic "health check" file for the entire experiment.


```bash

# Generate the Master Report

multiqc exercise/_data/ -o exercise/_data/ -n multiqc_report.html --force

```

![[multiqc_rseqc]]

# 4. Quantification
## Tool: `subread` (featureCount)

We use `featureCounts` from the Subread package to count reads that map to genes.

**Installation:**
```bash
mamba install subread
```

**Why featureCounts?**
- Highly efficient.
- Handles multi-mapping reads flexibly (though we default to ignoring them).
- Returns a raw count matrix suitable for DESeq2/EdgeR.
[[scripts#featureCounts Quantification Script]]

**Execution:**
```bash
./exercise/_data/_scripts/quantification_featureCounts_auto.sh
```

[[scripts#Biotype to MultiQC Conversion Script]]

**Result:**
- `gene_counts.txt`: Raw read counts for every gene (for DESeq2).
- `biotype_counts.txt`: Counts aggregated by gene type (e.g., protein_coding, rRNA) for QC.

# 5. Downstream Analysis (R/Bioconductor)

After generating raw counts, we performed a comprehensive downstream analysis including normalization, dispersion estimation, DGE, and functional enrichment (ORA & GSEA).

**Environment Setup:**
We used a dedicated R environment with `DESeq2`, `clusterProfiler`, and `EnhancedVolcano`.
```bash
# Setup: exercise/_data/_scripts/create_downstream_env.sh
source ./exercise/_data/_scripts/create_downstream_env.sh
```

## 5.1 Data Preparation & Normalization
- **Pre-filtering:** Genes with < 10 counts in < 3 samples were removed to reduce noise and increase power.
- **Normalization:** We used the **Median of Ratios** method (DESeq2) to correct for library size and composition bias.
  
![Normalization Check](./results/figures/02_normalization_check.png)
*Figure 5.1: Boxplots of log2 counts before and after normalization, showing improved comparability across samples.*

## 5.2 Differential Gene Expression (DGE)
Analysis was performed using a Negative Binomial GLM (DESeq2) comparing **Treatment (_snf2_ mutant)** vs **Control (WT)**.

### 5.2.1 Dispersion & Shrinkage
We estimated gene-wise dispersions and applied **LFC Shrinkage** (using `apeglm`) to handle high variance in low-count genes.

| Raw MA Plot | Shrunk MA Plot |
| :--- | :--- |
| ![MA Raw](./results/figures/02_ma_plot_raw.png) | ![MA Shrunk](./results/figures/02_ma_plot_shrunk.png) |
*Figure 5.2: MA plots showing the effect of LFC shrinkage in reducing noise for low-abundance genes.*

### 5.2.2 Results Summary
- **Total Significant DEGs** (padj < 0.05, |log2FC| > 1): **366**
  - **Up-regulated:** 138
  - **Down-regulated:** 228

| GeneID | log2FC | padj | Direction |
| :--- | :--- | :--- | :--- |
| **YOR290C** | -8.39 | 4.60e-23 | Down |
| **YHR215W** | -5.17 | 1.89e-25 | Down |
| **YIR018C-A** | 4.50 | 7.90e-04 | Up |
| **YGR051C** | 3.26 | 3.65e-10 | Up |

## 5.3 Functional Enrichment
### 5.3.1 Over-Representation Analysis (ORA)
Significant DEGs were tested for enrichment in GO Biological Processes.
- **Top Processes:** Oxoacid metabolic process, Organic acid metabolic process, IMP metabolic process.
![ORA Dotplot](./results/figures/03_ora_dotplot.png)

### 5.3.2 Gene Set Enrichment Analysis (GSEA)
GSEA was performed on the full ranked gene list (ranked by LFC) to capture coordinated changes in pathways.
- **Top Enriched:** Ribose phosphate metabolic process, cytoplasmic translation, ribosomal biogenesis.
![GSEA Dotplot](./results/figures/03_gsea_dotplot.png)
![GSEA Ridgeplot](./results/figures/03_gsea_ridgeplot.png)

## 5.4 Exploratory Visualizations
We used **Variance Stabilizing Transformation (VST)** for all exploratory plots to ensure homoscedasticity.

### PCA & Sample Distances
![PCA Plot](./results/figures/04_pca_plot.png)
![Sample Distance](./results/figures/04_sample_dist_heatmap.png)
*The samples cluster perfectly by condition, indicating high biological reproducibility.*

### DEGs Overview
![Volcano Plot](./results/figures/04_volcano_plot.png)
![Top 30 Heatmap](./results/figures/04_top30_heatmap.png)

Read more in [[Atlas/LuuLoi_RNA-seq_course/exercise/results/summary/_summary|_summary]].
