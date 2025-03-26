#!/bin/bash
FASTALIST=$1
OUTDIR=$2
COVERAGE=$3
# check if $1 and $2 are provided
if [ -z "$FASTALIST" ] || [ -z "$OUTDIR" ] || [ -z "$COVERAGE" ]; then
    echo "Usage: $0 <FASTALIST> <OUTDIR> <COVERAGE>"
    exit 1
fi

mkdir -p $OUTDIR

# Iterate over the list of fasta files
# Each line contains the path to the fasta file which includes the assembly accession
# Get the assembly accession from the fasta file path and use it as the read name prefix
# The regex of assembly accession is GC[AF]_[0-9]+\.[0-9]+
while read -r FASTA; do
    # Get the assembly accession from the fasta file path
    ASSEMBLY_ACCESSION=$(echo $FASTA | grep -oP 'GC[AF]_[0-9]+\.[0-9]+')
    echo "Simulating reads for $ASSEMBLY_ACCESSION"
    
    # Get file size of the fasta file
    GENOME_SIZE=$(stat -c %s $FASTA)
    READ_NUM=$((GENOME_SIZE * $COVERAGE / 300))
    # echo "Genome size: $GENOME_SIZE"
    # echo "Read number: $READ_NUM"
   
    ~/mason2-2.0.9-Linux-x86_64/bin/mason_simulator -q \
        --illumina-read-length 150 \
        --illumina-prob-mismatch 0.0011 \
        --illumina-prob-mismatch-begin 0.00055 \
        --illumina-prob-mismatch-end 0.0022 \
        --fragment-mean-size 500 \
        --read-name-prefix "${ASSEMBLY_ACCESSION}_" \
        -ir "${FASTA}" \
        -n "${READ_NUM}" \
        -o "${OUTDIR}/${ASSEMBLY_ACCESSION}_${COVERAGE}_1.fasta" \
        -or "${OUTDIR}/${ASSEMBLY_ACCESSION}_${COVERAGE}_2.fasta"
done < $FASTALIST

