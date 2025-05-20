# Master-Thesis
A Pectin-Based Prebiotic Fiber Modulates Liver Transcriptome Dysregulation in Diet-Induced Obese Mice. Transcriptomic analysis in R.

## Description
This repository contains the Bash and R scripts used for transcriptomic analysis to investigate the effects of olive pomace-derived pectin  on obesity-induced hepatic dysregulation in mice. The analysis include data preprocessing, normalization, differential gene expression analysis, enrichment anaylsis (GO and KEGG) and sPLS-DA modelling to explore how gene expression is altered by a high fat diet and the supplementation of pectin. 

The samples consist of whole liver tissue from three standard diet (SD, control) samples, three high-fat diet (HFD) samples, and three high-fat diet samples supplemented with pectin (HFDpp). The sequencing technology used to generate the FASTA files was DNB-Seq G400 (BGI Genomics).

## Contents
#### Bash script
This script contains the full bash pipeline used for processing raw RNA-Seq data. It begins with genome indexing using STAR (v2.7.11b) with the Mus musculus GRCm39 genome and corresponding GTF annotation from Ensembl. STAR is then used to align paired-end FASTQ reads, generating sorted, strand-specific BAM files. After alignment, BAM files were indexed and quality-checked using Samtools. Transcript abundance was then quantified using StringTie (v2.1.3b) in two stages: first, assembling transcripts per sample and second, quantifying expression using the reference annotation. Output files include per-sample GTFs and expression tables in TSV format. These were subsequently used for the generation of a gene-level count matrix via the prepDE.py script, which served as input for downstream differential expression analyses in R.

#### R script
This analysis was performed in R and covers the entire transcriptomic pipeline from raw TPM quantification to differential expression and enrichment. The workflow integrates tools for preprocessing, normalization, multivariate modeling, and functional interpretation of RNA-Seq data from murine liver samples.

*1. Data Loading & Preprocessing*: TPM matrices were generated from StringTie .tsv files using a custom R function. Expression data were log-transformed after adding a pseudo-count of 1 to avoid log(0) issues. Exploratory plots such as boxplots and PCA were used to assess expression distribution across samples.

*2. Normalization & Quality Control*: quantile normalization was performed with NormalyzerDE. PCA and replicate scatterplots were used pre- and post-normalization to evaluate technical variability and biological consistency. 

*3. Cell Type Estimation*: to confirm tissue homogeneity, deconvolution was performed using MuSiC and a publicly available liver single-cell RNA-seq dataset.

*4. Differential Expression Analysis*: count matrices were input to DESeq2, and three pairwise contrasts were evaluated: HFD vs Control, HFDpp vs HFD, and HFDpp vs Control. Genes with |log2FoldChange| ≥ 2 and adjusted p-value < 0.05 were considered differentially expressed. Volcano plots were used to visualize significance and effect size.

*5. Gene Overlap & Categorization*: differentially expressed genes were categorized by condition, including genes uniquely altered by pectin or restored to normal expression. Venn diagrams helped identify overlap across contrasts.

*6. Functional Enrichment Analysis*: clusterProfiler was used to run GO (BP, CC, MF) and KEGG enrichment analyses on each gene category.

*7. Multivariate Modeling (sPLS-DA)*: to identify the most discriminatory genes, an sPLS-DA model was trained with mixOmics. Top contributing genes were extracted from components 1 and 2 and visualized in ranked barplots.

Cytoscape, together with ClueGO, was used to generate gene enrichment networks based on the differentially expressed genes (DEGs) identified.
