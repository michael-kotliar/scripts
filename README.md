# Scripts

### Fetch genome data from UCSC Genome Browser

**General info**

For every genome in [`mm10`, `hg19`, `hg38`] for selected chromosomes only:

  - download reference genome as a single FASTA file (keep a copy of *chrM.fa* separately)
  - download ribosomal DNA as FASTA file
  - download refGene annotation as tab-delimited file
  - extend downloaded annotation with chrM from GENCODE
  - filter extended annotation to include only selected chromosomes
  - generate GTF file based on tab-delimited annotation file


**Running instruction** ***!!! You need to have Docker installed !!!***

When run as
```
./fetch_data.sh
```
the results will be saved in the current directory as `./genome_indices` folder with the following structure

```
└── genome_indices
    └── inputs
        ├── mm10
        │   ├── annotation
        │   │   ├── refgene.gtf
        │   │   └── refgene.tsv
        │   └── fasta
        │       ├── chrM.fa
        │       ├── mm10.fa
        │       └── ribo.fa
        ├── hg19
        │   ...
        └── hg38
            ...
```
If directory `./genome_indices` already exist, skip downloading.
