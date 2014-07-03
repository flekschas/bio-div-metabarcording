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

# Blast number of threads
NUM_THREADS=4

# Fixed read length for uparse
UPARSE_READ_LEN=300



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

printf "Create BLAST DB... "

if [[ -f "$BLASTDB.nhr" && \
      -f "$BLASTDB.nin" && \
      -f "$BLASTDB.nsq" && \
      $CACHE = true ]];
then
    echo "(cached)"
else
    START=`date +%s`

    $MAKEBLASTDB -in $BLASTDB -dbtype nucl > "$BASE/logs/blast.log"

    END=`date +%s`
    RUNTIME=$((END-START))

    echo "($RUNTIME sec)"
fi



# Prepare reads
# ------------------------------------------------------------------------------
# 1. Convert SFF to FASTQ
# 2. Demultiplex reads
# 3. Remove primer, barcodes and bases with a low quality
# 4. Sub-sample reads

cd "$BASE/$DATA"

printf "Convert SFF to FASTQ... "

START=`date +%s`
ALL_CACHED=$CACHE

for SFF in *.sff;
do
    # Extract file name
    FILENAME=$(echo "${SFF}" | perl -nle 'm/([^\/]+)\.sff$/; print $1')

    # Convert SFF to FASTQ if not already done
    if [[ ! -f "$FILENAME.fq" || $CACHE = false ]];
    then
        ALL_CACHED=false
        "$SFF4FASTQ" $SFF > "$FILENAME.fq"
    fi
done

END=`date +%s`
RUNTIME=$((END-START))

if [ $ALL_CACHED = false ];
then
    echo "($RUNTIME sec)"
else
    echo "(cached)"
fi

mkdir -p demultiplexed/tmp

printf "Demultiplex reads... "

START=`date +%s`

# Demultiplex each FASTQ file on its own to have distinct files for each month
for FQ in *.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)\.fq$/; print $1')

    cat $FQ | $FASTXBCS --bcfile "$BASE/$EXTRAS/$BARCODES" \
    --prefix demultiplexed/tmp/$FILENAME"_" --bol --mismatches $DEMUXMM --suffix ".fq" \
    > "$BASE/logs/demultiplexing_$FILENAME.log"
done

# Concatenate reads that have multiple barcodes but arise from one habitat
for FQ in demultiplexed/tmp/*.fq;
do
    # Extract file name
    HABITAT=$(echo "${FQ}" | perl -nle 'm/([^\/_]+)_([^\/_]+)_([0-9])*\.fq$/; print $2')
    MONTH=$(echo "${FQ}" | perl -nle 'm/([^\/_]+)_([^\/_]+)_([0-9])*\.fq$/; print $1')

    [ -f "demultiplexed/"$HABITAT"_"$MONTH".fq" ] || \
    cat "demultiplexed/tmp/"$MONTH"_$HABITAT"*.fq > "demultiplexed/"$HABITAT"_"$MONTH".fq"
done

END=`date +%s`
RUNTIME=$((END-START))

echo "($RUNTIME sec)"

# Remove temporary folder to save disk space
rm -R demultiplexed/tmp

# Remove empty .fq file
# Caused by cat on a Mac
[ -f .fq ] && rm .fq
[ -f demultiplexed/_.fq ] && rm demultiplexed/_.fq

mkdir -p trimmed
mkdir -p subsamples

echo "Trim and subsample reads"

# Remove barcode, primer and bases with too low quality
for FQ in demultiplexed/*.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)\.fq$/; print $1')

    [[ -f "trimmed/$FILENAME.fq" && $CACHE = true ]] || \
    java -jar "$TRIMMOMATIC" SE -phred33 \
    -trimlog "$BASE/logs/trimmomatic.$FILENAME.log" \
    $FQ "trimmed/$FILENAME.fq" \
    HEADCROP:$TRIM_BC_LEN \
    ILLUMINACLIP:"$BASE/$EXTRAS/$PRIMER":2:30:10 \
    LEADING:$TRIM_LEAD_Q TRAILING:$TRIM_TRAIL_Q \
    SLIDINGWINDOW:$TRIM_WIN_LEN:$TRIM_WIN_Q MINLEN:$TRIM_MIN_LEN

    # Add barcodelabel to read IDs
    # Needed because uparse demultiplexed seems to be broken
    sed "s/^@[a-zA-Z0-9]*$/&;barcodelabel=$FILENAME/" < trimmed/$FILENAME.fq > trimmed/$FILENAME.new.fq
    rm trimmed/$FILENAME.fq
    mv trimmed/$FILENAME.new.fq trimmed/$FILENAME.fq

    # Sub-sample reads
    [[ -f "subsamples/$FILENAME.fq" && $CACHE = true ]] || \
    "$BASE/$SCRIPTS/subsample_se_fastq.bash" "trimmed/$FILENAME.fq" \
    "subsamples/$FILENAME.fq" $SUBSAMPLES
done



# BLAST reads
# ------------------------------------------------------------------------------
# Blast each subsamples against your BLAST DB

cd "$BASE/$BLAST"

mkdir -p hits

printf "BLAST: "

for FQ in "$BASE/$DATA/subsamples/"*.fq;
do
    # Extract file name
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)*\.fq$/; print $1')
    HABITAT=$(echo "${FILENAME}" | perl -nle 'm/([^_]+)_([^_]+)$/; print $1')
    MONTH=$(echo "${FILENAME}" | perl -nle 'm/([^_]+)_([^_]+)$/; print $2')

    START=`date +%s`
    ALL_CACHED=$CACHE

    printf "$FILENAME "

    if [ "$FILENAME" != "unmatched" ];
    then
        # Convert FASTQ to FASTA on the fly and BLAST the reads
        if [[ ! -f "hits/$FILENAME.txt" || $CACHE = false ]];
        then
            ALL_CACHED=false
            awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' "$FQ" | \
            blastn -db $BLASTDB -out hits/$FILENAME.txt -query - -num_threads $NUM_THREADS
        fi
    fi

    # Copy and rename hits to be able to compare months in MEGAN
    [[ -f hits_rearranged/$MONTH"_"$HABITAT.txt && $CACHE = true ]] || \
    cp hits/$FILENAME.txt hits_rearranged/$MONTH"_"$HABITAT.txt

    END=`date +%s`
    RUNTIME=$((END-START))

    if [ $ALL_CACHED = false ];
    then
        printf "($RUNTIME sec) "
    else
        printf "(cached) "
    fi

done

echo ""



# Generate OTUs
# ------------------------------------------------------------------------------
#

cd "$BASE/$DATA"

# Trim reads to a fixed length and convert FASTQ to FASTA
cat trimmed/*.fq | \
"$BASE/$SCRIPTS/trim.py" $UPARSE_READ_LEN | \
awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' - \
> "$DATA/$UPARSE/all.fa"

cd "$DATA/$UPARSE"

mkdir -p otus

# Dereplicate rads
$USEARCH -derep_fulllength all.fa -sizeout -output all.derep.fa

# Sort reads by size and throw away everything that's smaller than 2
$USEARCH -sortbysize all.derep.fa -minsize 2 -output all.sorted.fa

# Cluster OTUs
$USEARCH -cluster_otus all.sorted.fa -otus otus/otus.fa

# Remove chimera
$USEARCH -uchime_ref otus/otus.fa -otus otus.fa -db "$BASE/$BLAST/$BLASTDB" -strand plus -nonchimeras otus/otus.no_chimaras.fa

"$BASE/$SCRIPTS/usearch/fasta_number.py" otus/otus.no_chimaras.fa OTU_ > otus/otus.numbered.fa

# Map reads back to the OTUs
for FQ in "$BASE/$DATA/trimmed/"*.fq
do
    FILENAME=$(echo "${FQ}" | perl -nle 'm/([^\/]+)\.fq$/; print $1')

    "$BASE/$SCRIPTS/trim.py" $UPARSE_READ_LEN < $FQ | \
    awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' - \
    > "$BASE/$DATA/trimmed/$FILENAME.fa"

    # Map reads (including singletons) back to OTUs
    $USEARCH -usearch_global "$BASE/$DATA/trimmed/$FILENAME.fa" -db otus/otus.numbered.fa -strand plus -id 0.97 -uc otus/$FILENAME.uc

    # Create OTU table
    "$BASE/$SCRIPTS/usearch/uc2otutab.py" otus/$FILENAME.uc > otus/$FILENAME.txt
done