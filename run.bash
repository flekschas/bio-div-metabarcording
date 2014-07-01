#!/bin/bash

# Config
# ------------------------------------------------------------------------------
# Set your configs

# Paths to folders
BASE="/Users/Fritz/Documents/Studium/BioInformatik/Master/Module/Biodiversity and Evolution/Exercise/2/tool"
BLAST="../blast"
DATA="../data"
EXTRAS="extras"
SCRIPTS="scripts"
UPARSE="../uparse"

# BLAST Database
# Please specify the file name of your FASTA file, that is contained in the
# $BLAST directory specified above, which should be turned into a BLAST DB.
BLASTDB="LSURef_115_tax_silva.fasta"

# Extra files
# Please make sure that all files listed below are within the $EXTRA directory
BARCODES="barcodes.csv"
PRIMER="primer.fa"

# Applications
# These should be absolute paths!
FASTXBCS="fastx_barcode_splitter.pl"
MAKEBLASTDB="makeblastdb"
SFF4FASTQ="sff2fastq"
TRIMMOMATIC="/Applications/trimmomatic-0.32/trimmomatic-0.32.jar"
USEARCH="usearch"

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

# Number of sub-samples
SUBSAMPLES=500



# Parameters
# ------------------------------------------------------------------------------
# See usage to get an overview of all parameters

CACHE=false

while getopts ":hcs:" opt; do
    case $opt in
    h)
        echo ""
        echo "USAGE:   run.bash [<options>]"
        echo ""
        echo "OPTIONS: -h    Show help"
        echo "         -c    Use cached files if available (much faster)"
        echo "         -s    Number of sum-samples used for BLASTing"
        echo ""
        exit 0
        ;;
    c)
        CACHE=true
        ;;
    s)
        SUBSAMPLES=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done



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

[[ -f "$BLASTDB.nhr" && \
   -f "$BLASTDB.nin" && \
   -f "$BLASTDB.nsq" && \
   $CACHE ]] || \
$MAKEBLASTDB -in $BLASTDB -dbtype nucl



# Prepare reads
# ------------------------------------------------------------------------------
# 1. Convert SFF to FASTQ
# 2. Demultiplex reads
# 3. Remove primer, barcodes and bases with a low quality
# 4. Sub-sample reads

cd "$BASE/$DATA"

echo "Convert SFF to FASTQ"

for SFF in *.sff;
do
    # Extract file name
    FILENAME=$(echo "${SFF}" | perl -nle 'm/([^\/]+)\.sff$/; print $1')

    # Convert SFF to FASTQ if not already done
    [[ -f "$FILENAME.fq" && $CACHE ]] || \
    "$BASE/$SFF4FASTQ" $SFF > "$FILENAME.fq"
done

mkdir -p demultiplexed

# # Test if reads are already demultiplexed
# if [];
# then

# fi

echo "Demultiplex reads"

# Demultiplex all reads at once
cat *.fq | $FASTXBCS --bcfile "$BASE/$EXTRAS/$BARCODES" \
--prefix "demultiplexed/" --bol --mismatches $DEMUXMM --suffix ".fq" \
> "$BASE/logs/demultiplexing.log"

# Remove empty .fq file
# Created when running the script on a Mac
[ -f .fq ] && rm .fq

mkdir -p trimmed
mkdir -p subsamples

echo "Trim and subsample reads"

# Remove barcode, primer and bases with too low quality
for FQ in demultiplexed/*.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)\.fq$/; print $1')

    [[ -f "trimmed/$FILENAME.fq" && $CACHE ]] || \
    java -jar "$TRIMMOMATIC" SE -phred33 \
    -trimlog "$BASE/logs/trimmomatic.$FILENAME.log" \
    $FQ "trimmed/$FILENAME.fq" \
    HEADCROP:$TRIM_BC_LEN \
    ILLUMINACLIP:"$BASE/$EXTRAS/$PRIMER":2:30:10 \
    LEADING:$TRIM_LEAD_Q TRAILING:$TRIM_TRAIL_Q \
    SLIDINGWINDOW:$TRIM_WIN_LEN:$TRIM_WIN_Q MINLEN:$TRIM_MIN_LEN

    # Sub-sample reads
    [[ -f "subsamples/$FILENAME.fq" || $CACHE ]] || \
    "$BASE/$SCRIPTS/subsample_se_fastq.bash" "trimmed/$FILENAME.fq" \
    "subsamples/$FILENAME.fq" $SUBSAMPLES
done



# BLAST reads
# ------------------------------------------------------------------------------
#

cd "$BASE/$BLAST"

mkdir -p hits

printf "BLAST: "

for FQ in "$BASE/$DATA/subsamples/"*.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/_]+)(_[0-9]+)*\.fq$/; print $1')

    printf "$FILENAME... "

    # Convert FASTQ to FASTA on the fly and BLAST the reads against the BLAST DB
    cat "$BASE/$DATA/subsamples/$FILENAME"*.fq | \
    awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' - | \
    blastn -db $BLASTDB -out hits/$FILENAME.xml -query - -outfmt 5
done

echo ""



# # BLAST reads
# # ------------------------------------------------------------------------------
# #

# cd "$BASE/$UPARSE"

# mkdir -p sorted

# for FQ in "$BASE/$DATA/trimmed/"*.fq;
# do
#     # Extract file name WITHOUT _[number].fq
#     FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/_]+)(_[0-9]+)*\.fq$/; print $1')



#     $USEARCH -sortbysize seqs.fasta -output seqs_sorted.fasta -minsize 4
# done
