#!/bin/bash
# http://userweb.eng.gla.ac.uk/umer.ijaz/bioinformatics/subsampling_reads.pdf
# [usage] subsample_se_fastq.bash input.fastq output.fastq number-of-samples
cat $1 | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' | awk -v k=$3 'BEGIN{srand(systime() + PROCINFO["pid"]);}{s=x++<k?x-1:int(rand()*x);if(s<k)R[s]=$0}END{for(i in R)print R[i]}' | awk -F "\t" -v f="$2" '{print $1"\n"$2"\n"$3"\n"$4 > f}'