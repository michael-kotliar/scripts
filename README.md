# Scripts

### Fetch genome data from UCSC Genome Browser

For every genome in [`mm10`, `hg19`, `hg38`] do:

  - download reference genome into a single FASTA file
  - download refGene annotation into TSV file
  - extend refGene annotation with chrM from GENCODE
  - generate GTF file based on TSV annotation file
  
```
./fetch_data.sh
```
