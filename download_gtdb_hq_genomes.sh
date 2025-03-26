#!/bin/bash
DBDIR=$1
COMP=$2
CONTEM=$3
# check if $1 and $2 are provided
if [ -z "$DBDIR" ] || [ -z "$COMP" ] || [ -z "$CONTEM" ]; then
    echo "Usage: $0 <DBDIR> <MIN_COMPLETENESS(0-100)> <MAX_CONTAMINATION(0-100)>"
    exit 1
fi

# Filter based on metadata
## Assembly level = Complete or Chromosome
## Checkm_contamination < 5
## Checkm_completeness > 90

# Get the column number of "ncbi_assembly_level", "checkm2_completeness", and "checkm2_contamination"
assembly_level_col=$(head -1 $DBDIR/gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^ncbi_assembly_level$' | cut -d: -f1)
checkm_completeness_col=$(head -1 $DBDIR/gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^checkm2_completeness$' | cut -d: -f1)
checkm_contamination_col=$(head -1 $DBDIR/gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^checkm2_contamination$' | cut -d: -f1)
# assembly_accession_col=$(head -1 $DBDIR/gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^ncbi_genbank_assembly_accession$' | cut -d: -f1)

# If checkm2 completeness and contamination are not found, use checkm completeness and contamination
if [ -z "$checkm_completeness_col" ]; then
    checkm_completeness_col=$(head -1 gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^checkm_completeness$' | cut -d: -f1)
fi

if [ -z "$checkm_contamination_col" ]; then
    checkm_contamination_col=$(head -1 gtdb_metadata.tsv | tr '\t' '\n' | grep -n '^checkm_contamination$' | cut -d: -f1)
fi

awk -v assembly_level_col="$assembly_level_col" \
    -v checkm_completeness_col="$checkm_completeness_col" \
    -v checkm_contamination_col="$checkm_contamination_col" \
    -v COMP="$COMP" \
    -v CONTEM="$CONTEM" \
    -F '\t' \
    '{ if (($assembly_level_col == "Complete Genome" || $assembly_level_col == "Chromosome") && ($checkm_contamination_col < $CONTEM) && ($checkm_completeness_col > &COMP)) 
        {
            print substr($1, 4)
        } 
    }' \
    $DBDIR/gtdb_metadata.tsv > $DBDIR/filtered_assembly_accession.tsv

awk -F '.' '{print $1}' $DBDIR/filtered_assembly_accession.tsv > $DBDIR/filtered_assembly_accession_no_version.tsv

grep "GCF" $DBDIR/filtered_assembly_accession_no_version.tsv > $DBDIR/filtered_assembly_accession_no_version_refseq.tsv
grep "GCA" $DBDIR/filtered_assembly_accession_no_version.tsv > $DBDIR/filtered_assembly_accession_no_version_genbank.tsv

# Download Genbank assembly summary
aria2c -x 16 -j 16 -s 16 \
    https://ftp.ncbi.nlm.nih.gov/genomes/genbank/archaea/assembly_summary.txt \
    -d $DBDIR
mv $DBDIR/assembly_summary.txt $DBDIR/assembly_summary_archaea_gb.txt

aria2c -x 16 -j 16 -s 16 \
    https://ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt \
    -d $DBDIR
mv $DBDIR/assembly_summary.txt $DBDIR/assembly_summary_bacteria_gb.txt

# Download RefSeq assembly summary
aria2c -x 16 -j 16 -s 16 \
    https://ftp.ncbi.nlm.nih.gov/genomes/refseq/archaea/assembly_summary.txt \
    -d $DBDIR
mv $DBDIR/assembly_summary.txt $DBDIR/assembly_summary_archaea_rs.txt

aria2c -x 16 -j 16 -s 16 \
    https://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt \
    -d $DBDIR
mv $DBDIR/assembly_summary.txt $DBDIR/assembly_summary_bacteria_rs.txt

# Get ftp path for each filtered assembly accession
grep -f $DBDIR/filtered_assembly_accession_no_version_genbank.tsv $DBDIR/assembly_summary_archaea_gb.txt \
    | awk -F '\t' '{print $20}' > $DBDIR/ftp_path_genomic_tmp.txt

grep -f $DBDIR/filtered_assembly_accession_no_version_genbank.tsv $DBDIR/assembly_summary_bacteria_gb.txt \
    | awk -F '\t' '{print $20}' >> $DBDIR/ftp_path_genomic_tmp.txt

grep -f $DBDIR/filtered_assembly_accession_no_version_refseq.tsv $DBDIR/assembly_summary_archaea_rs.txt \
    | awk -F '\t' '{print $20}' >> $DBDIR/ftp_path_genomic_tmp.txt

grep -f $DBDIR/filtered_assembly_accession_no_version_refseq.tsv $DBDIR/assembly_summary_bacteria_rs.txt \
    | awk -F '\t' '{print $20}' >> $DBDIR/ftp_path_genomic_tmp.txt

awk -F '/' '{print $0"/"$NF"_genomic.fna.gz"}' $DBDIR/ftp_path_genomic_tmp.txt > $DBDIR/ftp_path_genomic_fna.txt

# Download genomes
mkdir -p $DBDIR/genomes
aria2c -x 16 -j 16 -s 16 -i $DBDIR/ftp_path_genomic_fna.txt -d $DBDIR/genomes
find $DBDIR/genomes -type f -name "*.fna.gz" > $DBDIR/downloaded_files.txt