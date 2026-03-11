# MultiQC Analysis: STAR Alignment

This report summarizes the STAR alignment results for the RNA-seq samples.

## Summary Table

| Sample    | Total Reads | Uniquely Mapped (%) | Multimapped (%) | Unmapped (Too Short) (%) | Overall Mapped (%) |
| :-------- | :---------: | :-----------------: | :-------------: | :----------------------: | :----------------: |
| ERR458497 |   846,040   |       85.77%        |     10.18%      |          2.89%           |       95.95%       |
| ERR458498 |   851,243   |       85.76%        |     10.20%      |          2.88%           |       95.96%       |
| ERR458499 |  1,093,200  |       85.67%        |     10.25%      |          2.91%           |       95.92%       |
| ERR458500 |  1,885,330  |       89.53%        |      7.59%      |          2.11%           |       97.12%       |
| ERR458501 |  1,870,525  |       89.50%        |      7.63%      |          2.10%           |       97.13%       |
| ERR458502 |  1,853,031  |       89.55%        |      7.61%      |          2.08%           |       97.16%       |

## Key Observations

1. **High Mapping Efficiency**: All samples show excellent mapping rates, with overall mapped percentages exceeding 95%.
2. **Consistency Across Samples**: The samples appear to fall into two groups based on sequencing depth (ERR458497-499 around 0.8-1.1M reads, and ERR458500-502 around 1.8M reads). Despite the difference in depth, the mapping percentages remain very consistent within each group and across all samples.
3. **Uniquely Mapped Reads**: Most reads mapped uniquely to the genome (85% - 90%), which is a good indicator of high-quality sequencing data and a well-annotated reference genome.
4. **Multimapped Reads**: Approximately 7% to 10% of reads were multimapped. This is within a normal range for RNA-seq experiments, often representing reads from repetitive regions or gene families.
5. **Unmapped Reads**: A small fraction of reads (~2-3%) remained unmapped, primarily due to being "too short" after potential trimming or due to biological sequences not present in the reference.

## Conclusion

The STAR alignment was **successful** for all samples, providing high-quality mapped data suitable for downstream differential expression analysis. The high unique mapping rate suggests that the library preparation and sequencing were of high quality.
