#!/bin/bash

# Config
# ------------------------------------------------------------------------------
# Set your configs

# Paths to folders
BASE="/Users/Fritz/Documents/Studium/BioInformatik/Master/Module/Biodiversity and Evolution/Exercise/2/tool"
BLAST="../blast"
DATA="../data"
EXTRAS="extras"

# Applications
FASTXBCS="fastx_barcode_splitter.pl"
MAKEBLASTDB="makeblastdb"
SFF4FASTQ="/Applications/Bioinformatics/sff2fastq"
TRIMMOMATIC="/Applications/trimmomatic-0.32/trimmomatic-0.32.jar"

# Application parameters
# Number of mismatches for demultiplexing
DEMUXMM=1
# Trimmomatic settings
# Barcode length will simply be cutted from the beginning
TRIM_BC_LEN=10
# Bases with a PHRED score lower than specified will be removed from the
# begining of the read
TRIM_LEAD_Q=3
# Bases with a PHRED score lower than specified will be removed from the
# end of the read
TRIM_TRAIL_Q=3
# Window size that Trimmomatic uses to asses average qualit
TRIM_WIN_LEN=4
# Remove windows with a average phred score that is lover than specified
TRIM_WIN_Q=14
# Remove reads which are shorter than the given number of bases
TRIM_MIN_LEN=20

# Tests and Preperation
# ------------------------------------------------------------------------------
# Set your configs

# Define a logging folder
mkdir -p "$BASE/logs"

# Create BLAST DB
# ------------------------------------------------------------------------------
# We use the Silva DB

cd "$BASE/$BLAST"

# If the BLAST DB does not exist, create it

[[ -f "LSURef_115_tax_silva.fasta.nhr" && \
   -f "LSURef_115_tax_silva.fasta.nin" && \
   -f "LSURef_115_tax_silva.fasta.nsq" ]] || \
$MAKEBLASTDB -in ./LSURef_115_tax_silva.fasta -dbtype nucl



# Prepare reads
# ------------------------------------------------------------------------------
# 

cd "$BASE/$DATA"

for SFF in *.sff;
do
    # Extract file name
    FILENAME=$(echo "${SFF}" | perl -nle 'm/([^\/]+)\.sff$/; print $1')

    # Convert SFF to FASTQ if not already done
    [ -f "$FILENAME.fq" ] || \
    "$BASE/$SFF4FASTQ" $SFF > "$FILENAME.fq"
done

mkdir -p demultiplexed

# Demultiplex all reads at once
cat *.fq | $FASTXBCS --bcfile "$BASE/$EXTRAS/barcodes.csv" \
--prefix "demultiplexed/" --bol --mismatches $DEMUXMM --suffix ".fq" \
> "$BASE/logs/demultiplexing.log"

# Remove empty .fq file
# Created when running the script on a Mac
[ -f .fq ] && rm .fq

mkdir -p trimmed

# Remove barcode, primer and bases with too low quality
for FQ in demultiplexed/*.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)\.fq$/; print $1')

    java -jar "$TRIMMOMATIC" SE -phred33 \
    -trimlog "$BASE/logs/trimmomatic.$FILENAME.log" \
    $FQ "trimmed/$FILENAME.fq" \
    HEADCROP:$TRIM_BC_LEN \
    ILLUMINACLIP:"$BASE/$EXTRAS/primer.fa":2:30:10 \
    LEADING:$TRIM_LEAD_Q TRAILING:$TRIM_TRAIL_Q \
    SLIDINGWINDOW:$TRIM_WIN_LEN:$TRIM_WIN_Q MINLEN:$TRIM_MIN_LEN
done


# BLAST reads
# ------------------------------------------------------------------------------
# 

# awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' "$FILENAME.fq" \
# blastn -db blast/LSURef_115_tax_silva -out blast/hits.txt -query - -outfmt 6