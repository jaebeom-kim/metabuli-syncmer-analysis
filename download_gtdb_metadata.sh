#!/bin/bash
DBDIR=$1

# check if $1 and $2 are provided
if [ -z "$DBDIR" ]; then
    echo "Usage: $0 <DBDIR>"
    exit 1
fi

# Download GTDB metadata
aria2c -x 16 -j 16 -s 16 \
    https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/bac120_metadata.tsv.gz \
    -d $DBDIR
gzip -d $DBDIR/bac120_metadata.tsv.gz

aria2c -x 16 -j 16 -s 16 \
    https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/ar53_metadata.tsv.gz \
    -d $DBDIR
gzip -d $DBDIR/ar53_metadata.tsv.gz

# Concatenate metadata
(cat $DBDIR/bac120_metadata.tsv; tail -n +2 $DBDIR/ar53_metadata.tsv) > $DBDIR/gtdb_metadata.tsv
