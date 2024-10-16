#!/usr/bin/env bash
fastaIndex="$1"
gatkResource="$2"
bam="$3"
bam_bai="$4"
pathToBin="nextflow-bin"
nameOfSample=${bam%_markdup.*}

echo $nameOfSample
#download fasta and index files

mkdir genome
fastaIndex=$(echo ${fastaIndex}| sed 's|dx://||g')
fasta_file_name=$(dx describe ${fastaIndex} --name)
dx download "$fastaIndex" -o genome/"$fasta_file_name"

cd genome
tar zxvf $fasta_file_name
cd ..

ls
# prepare GATK resource files
mkdir resources
cd resources
gatkResource=$(echo ${gatkResource}| sed 's|dx://||g')
gatkResource_name=$(dx describe ${gatkResource} --name)
dx download "$gatkResource" -o "$gatkResource_name"
tar --no-same-owner -zxvf ${gatkResource_name} --strip 1
ls
cd ..
# give permission to run Sentieon
chmod -R 777 ${pathToBin}
# get sentieon license
source ${pathToBin}/license/license_setup.sh
set -eu
export SENTIEON_INSTALL_DIR=${pathToBin}/sentieon-genomics-*
SENTIEON_BIN_DIR=$SENTIEON_INSTALL_DIR/bin
SENTIEON_APP=$SENTIEON_BIN_DIR/sentieon
#exportlibjemalloc
export LD_PRELOAD=${pathToBin}/sentieon-genomics-202112.07/lib/libjemalloc.so.2
export MALLOC_CONF=metadata_thp:auto,background_thread:true,dirty_decay_ms:30000,muzzy_decay_ms:30000
#generate ignore_decoy bed file
grep -v "hs37d5" "genome/genome.fa.fai"|grep -v "chrEBV"|grep -v "hs38d1"|grep -v "decoy"|awk 'BEGIN{OFS="\t"}{print $1,0,$2}' > ignore_decoy.bed
#tnhaplotyper2
$SENTIEON_APP driver -t 36 -r genome/*.fa --interval ignore_decoy.bed -i ${bam} --algo QualCal -k resources/Homo_sapiens_assembly38.known_indels.vcf.gz -k resources/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz -k resources/Homo_sapiens_assembly38.dbsnp138.vcf.gz tumor_recal_data_Sentieon.table
$SENTIEON_APP driver -t 36 -r genome/*.fa -i ${bam} -q tumor_recal_data_Sentieon.table --interval ignore_decoy.bed --algo TNhaplotyper2 --tumor_sample ${nameOfSample} tnhaplotyper2.vcf.gz --algo OrientationBias --tumor_sample ${nameOfSample} ORIENTATION_DATA
$SENTIEON_APP driver -r genome/*.fa --algo TNfilter --tumor_sample ${nameOfSample} -v tnhaplotyper2.vcf.gz --orientation_priors ORIENTATION_DATA tnhaplotyper2.filtered.vcf.gz
#rename files
mv tnhaplotyper2.filtered.vcf.gz ${nameOfSample}_markdup_recalibrated_tnhaplotyper2.vcf.gz
mv tnhaplotyper2.filtered.vcf.gz.tbi ${nameOfSample}_markdup_recalibrated_tnhaplotyper2.vcf.gz.tbi
