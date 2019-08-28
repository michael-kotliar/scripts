#!/bin/bash
MM10_CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY chrM)
HG19_CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY chrM)
HG38_CHRS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY chrM)


get_fasta () {
  CUR=`pwd`
  GEN=$1
  DIR=$2
  CHR=${@:3}
  echo -e "\nDownload FASTA for $GEN into $DIR"
  mkdir -p $DIR && cd $DIR
  echo -e "\nEntering $DIR"
  if [ ! -f "ribo.fa" ] ; then
    echo "Process ribosomal"
    wget -q --show-progress https://biowardrobe.cchmc.org/indices/genomes/${GEN}/ribo.fa
    docker run --rm -ti -v `pwd`:/tmp/ biowardrobe2/samtools:v1.4 samtools faidx ribo.fa
  fi
  if [ ! -f ${GEN}.fa ] ; then
    for C in ${CHR[@]} ; do
      echo "Process $C"
      if [ ! -f ${C}.fa ] ; then
        F=${C}.fa.gz
        wget -q --show-progress ftp://hgdownload.cse.ucsc.edu/goldenPath/${GEN}/chromosomes/${F}
        gunzip $F
      fi
      cat ${C}.fa >> ${GEN}.fa
      if [ ${C}.fa != "chrM.fa" ] ; then
        rm -f ${C}.fa
      fi
    done
    docker run --rm -ti -v `pwd`:/tmp/ biowardrobe2/samtools:v1.4 samtools faidx ${GEN}.fa
    docker run --rm -ti -v `pwd`:/tmp/ biowardrobe2/samtools:v1.4 samtools faidx chrM.fa
  fi
  cd $CUR
  echo "Leaving $DIR"
}


get_annotation () {
  CUR=`pwd`
  GEN=$1
  DIR=$2
  echo -e "\nDownload refGene annotation for $GEN into $DIR"
  mkdir -p $DIR && cd $DIR
  echo -e "\nEntering $DIR"
  if [ ! -f "refgene.tsv" ] ; then
    echo -e "Process refGene.txt.gz"
    wget -q --show-progress http://hgdownload.cse.ucsc.edu/goldenPath/${GEN}/database/refGene.txt.gz
    gunzip refGene.txt.gz
    echo -e "Add chrM"
    case $GEN in
      "mm10")
        CHR_M="ftp://hgdownload.soe.ucsc.edu/goldenPath/mm10/database/wgEncodeGencodeBasicVM18.txt.gz"
        FILTER=${MM10_CHRS[@]}
        ;;
      "hg19")
        CHR_M="ftp://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/wgEncodeGencodeBasicV19.txt.gz"
        FILTER=${HG19_CHRS[@]}
        ;;
      "hg38")
        CHR_M="ftp://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeBasicV28.txt.gz"
        FILTER=${HG38_CHRS[@]}
        ;;
    esac
    wget -q --show-progress -O ${GEN}_chrM.txt.gz $CHR_M
    gunzip ${GEN}_chrM.txt.gz
    cat ${GEN}_chrM.txt | awk '{ if ($3=="chrM") print $0 }' >> refGene.txt
    rm -f ${GEN}_chrM.txt
    echo "Filter refGene.txt to include only $FILTER"
    cat refGene.txt | awk -v filter="$FILTER" 'BEGIN {split(filter, f); for (i in f) d[f[i]]} {if ($3 in d) print $0}' > refGene_filtered.txt
    mv refGene_filtered.txt refGene.txt
    echo "Convert refGene.txt to refgene.gtf"
    docker run --rm -ti -v `pwd`:/tmp/ biowardrobe2/ucscuserapps:v358 /bin/bash -c "cut -f 2- refGene.txt | genePredToGtf file stdin refgene.gtf"
    echo "Rename refGene.txt to refgene.tsv, add header"
    echo -e "bin\tname\tchrom\tstrand\ttxStart\ttxEnd\tcdsStart\tcdsEnd\texonCount\texonStarts\texonEnds\tscore\tname2\tcdsStartStat\tcdsEndStat\texonFrames" > refgene.tsv
    cat refGene.txt >> refgene.tsv
    rm -f refGene.txt
  fi
  cd $CUR
  echo "Leaving $DIR"
}


get_annotation "mm10" "./genome_indices/inputs/mm10/annotation"
get_fasta      "mm10" "./genome_indices/inputs/mm10/fasta" ${MM10_CHRS[@]}

get_annotation "hg38" "./genome_indices/inputs/hg38/annotation"
get_fasta      "hg38" "./genome_indices/inputs/hg38/fasta" ${HG38_CHRS[@]}

get_annotation "hg19" "./genome_indices/inputs/hg19/annotation"
get_fasta      "hg19" "./genome_indices/inputs/hg19/fasta" ${HG19_CHRS[@]}
