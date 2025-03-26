# metabuli-syncmer-analysis

## Download GTDB genomes and taxonomy
```
# 1. Download GTDB metadata
./download_gtdb_metadata.sh DBDIR

# 2. Download GTDB HQ genomes
./download_gtdb_hq_genomes.sh DBDIR MIN_COMPLETENESS MAX_CONTAMINATION

# 3. Download GTDB taxonomy
https://github.com/shenwei356/gtdb-taxdump/releases
```
The version of assemblies are ignored during download.
For example, when a GTDB entry has accession 'GCA_000000000.1', only 'GCA_000000000' is used to search the assembly in Genbank's assembly summary. 

## Make test sets
- `ASSEMBLY_ACCESSION_LIST`: list of downloaded assembly accessions. one per line. Assemblies having "ena-yuan" in their name are excluded. 
- `TAX_DUMP`: GTDB taxonomy dump file.

```
metabuli maketestsets ASSEMBLY_ACCESSION_LIST TAX_DUMP 
```
It generates
- ASSEMBLY_ACCESSION_LIST_databaseAssembly: assemblies to build a reference database.
- ASSEMBLY_ACCESSION_LIST.excludedGenera: assemblies to simulate novel genera reads.
- ASSEMBLY_ACCESSION_LIST.excludedSpecies: assemblies to simulate novel species reads.
- ASSEMBLY_ACCESSION_LIST.excludedAssembly: assemblies to simulate novel assembly reads.
- ASSEMBLY_ACCESSION_LIST.includedAssembly: assemblies to test assembly-specific read detection.

## Build a reference database
Using the generated `*_databaseAssembly` file, make a `REFERENCE_GENOMES` file that contains paths to reference genomes.
```
# DB not using syncmers
metabuli build DBDIR REFERENCE_GENOMES TAX_DUMP/taxid.map --taxonomy-path TAX_DUMP --gtdb 1 --make-library 0 --sycmer 0

# DB using syncmers
metabuli build SYCMER_DBDIR REFERENCE_GENOMES TAX_DUMP/taxid.map --taxonomy-path TAX_DUMP --gtdb 1 --make-library 0 --sycmer 1
``` 

## Simulate reads
```

```