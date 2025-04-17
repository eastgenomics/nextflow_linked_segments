#!/bin/bash
set -e -x -o pipefail

input_bam="$1"
input_bam_index="$2"
pathToBin="nextflow-bin"
input_bam_prefix=${input_bam%%.*}



echo "Value of input_bam: '$input_bam'"
echo "Value of input_bam_index: '$input_bam_index'"

echo "installing packages"

export SAMTOOLS=${pathToBin}/samtools-1.16*
tar -jxvf $SAMTOOLS
cd samtools-1.16.1
make
make install
export PATH=$pathToBin:$PATH
echo 'streaming files'
cd ..
ls

# dx download "$input_bam" -o input_bam
# dx download "$input_bam_index" -o input_bam_index

outfile=${input_bam_prefix}.flagstat
samtools flagstat $input_bam > $outfile
flagstat_output=$(dx upload $outfile --brief)
dx-jobutil-add-output flagstat_output "$flagstat_output" --class=file
