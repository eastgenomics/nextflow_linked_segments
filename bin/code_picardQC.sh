#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

# call in inputs from the command run in nextflow process
echo "Reading inputs"

fasta_index_path="$1"
bedfile_path="$2"
sorted_bam_path="$3"
sorted_bam_bai="$4"
run_CollectMultipleMetrics="$5"
run_CollectHsMetrics="$6"
run_CollectTargetedPcrMetrics="$7"
run_CollectRnaSeqMetrics="$8"
ref_annot_refflat_path="$9"

pathToBin="nextflow-bin"
sorted_bam_prefix="${sorted_bam_path%%.*}"
output_dir="./out/eggd_picard_stats/QC"

# download files
fasta_index_path=$(echo ${fasta_index_path}| sed 's|dx://||g')
fasta_file_name=$(dx describe ${fasta_index_path} --name)
bedfile_name=$(dx describe ${bedfile_path} --name)


dx download "$fasta_index_path" -o "$fasta_file_name"
dx download "$bedfile_path" -o "$bedfile_name"


echo $sorted_bam_bai

echo "inputs collected"
# run code for picard_qc, taken from code.sh

create_interval_file() {
	echo "create_interval_file"
	# Converts a BED file to a Picard Interval List
	# See https://gatk.broadinstitute.org/hc/en-us/articles/360037593251-BedToIntervalList-Picard-
	# Note that SD can take any of the follow. Here we are using the BAM.
	# - A file with .dict extension generated using Picard's CreateSequenceDictionaryTool
	# - A reference.fa or reference.fasta file with a reference.dict in the same directory
	# - Another IntervalList with @SQ lines in the header from which to generate a dictionary
	# - A VCF that contains #contig lines from which to generate a sequence dictionary
	# - A SAM or BAM file with @SQ lines in the header from which to generate a dictionary
	$java -jar ${pathToBin}/picard.jar BedToIntervalList \
	I="$bedfile_name" \
	O=targets.picard \
	SD="$sorted_bam_path"
}

collect_targeted_pcr_metrics() {
	echo "collect_targeted_pcr_metrics"
	# Call Picard CollectMultipleMetrics. Requires the co-ordinate sorted BAM file given to the app
	# as input. The file is referenced in this command with the option 'I=<input_file>'. Here, the
	# downloaded BAM file path is accessed using the DNAnexus helper variable $sorted_bam_path.
	# All outputs are saved to $output_dir (defined in main()) for upload to DNAnexus.
	$java -jar ${pathToBin}/picard.jar CollectTargetedPcrMetrics  I="$sorted_bam_path" R=genome.fa \
	O="$sorted_bam_prefix.targetPCRmetrics.txt" AI=targets.picard TI=targets.picard \
	PER_TARGET_COVERAGE="$sorted_bam_prefix.perTargetCov.txt"
}

collect_multiple_metrics() {
	echo "collect_multiple_metrics"
	# Call Picard CollectMultipleMetrics. Requires the co-ordinate sorted BAM file given to the app
	# as input. The file is referenced in this command with the option 'I=<input_file>'. Here, the
	# downloaded BAM file path is accessed using the DNAnexus helper variable $sorted_bam_path.
	# All outputs are saved to $output_dir (defined in main()) for upload to DNAnexus.
	# Note that not all outputs are relevent for all types of sequencing
	# e.g. some aren't applicable for amplicon NGC
	# Note that CollectSequencingArtifactMetrics errors out with TSO500 BAMs due to
	# "Record contains library that is missing from header" and so not used (fix unclear)
	$java -jar ${pathToBin}/picard.jar CollectMultipleMetrics I="$sorted_bam_path" R=genome.fa \
	PROGRAM=null \
	PROGRAM=CollectAlignmentSummaryMetrics \
	PROGRAM=CollectInsertSizeMetrics \
	PROGRAM=QualityScoreDistribution \
	PROGRAM=MeanQualityByCycle \
	PROGRAM=CollectBaseDistributionByCycle \
	PROGRAM=CollectGcBiasMetrics \
	PROGRAM=CollectQualityYieldMetrics \
	O="$sorted_bam_prefix"
	# PROGRAM=CollectSequencingArtifactMetrics \
}

collect_hs_metrics() {
	echo "collect_hs_metrics"
	# Call Picard CollectHsMetrics. Requires the co-ordinate sorted BAM file given to the app as
	# input (I=). Outputs the hsmetrics.tsv and pertarget_coverage.tsv files to $output_dir
	# (defined in main()) for upload to DNAnexus. Note that coverage cap is set to 100000 (default=200).
	$java -jar ${pathToBin}/picard.jar CollectHsMetrics BI=targets.picard TI=targets.picard I="$sorted_bam_path" \
	O="${sorted_bam_prefix}.hsmetrics.tsv" R=genome.fa \
	PER_TARGET_COVERAGE="${sorted_bam_prefix}.pertarget_coverage.tsv" \
	COVERAGE_CAP=100000
}

collect_rnaseq_metrics() {
	echo "collect_rnaseq_metrics"
	# Call Picard CollectRnaSeqMetrics. akes a SAM/BAM file containing
	# the aligned reads from an RNAseq experiment and produces metrics
	# describing the distribution of the bases within the transcripts
	$java -jar ${pathToBin}/picard.jar CollectRnaSeqMetrics \
    I="$sorted_bam_path" \
    O="${sorted_bam_prefix}.RNAmetrics.tsv" \
    REF_FLAT="$ref_flat" \
    STRAND=SECOND_READ_TRANSCRIPTION_STRAND
}

##### SETUP #####

echo "Running setup"

# Calculate 90% of memory size for java
mem_in_mb=$(head -n1 /proc/meminfo | awk '{print int($2*0.9/1024)}')
# Set java command with the calculated maximum memory usage

java="java -Xmx${mem_in_mb}m"

# export PICARD_JAR=${pathToBin}/picard.jar
# export GTF_TO_REFFLAT=${pathToBin}/GtftoRefflat-assembly-0.1.jar

# Unpack the reference genome for Picard. Produces genome.fa, genome.fa.fai, and genome.dict files.
tar zxvf $fasta_file_name

# Create directory for Picard stats files to be uploaded from the worker

mkdir -p $output_dir

##### MAIN #####

echo "Running"

# Create the interval file if required
if [ "$run_CollectMultipleMetrics" == true ] || [ "$run_CollectHsMetrics" == true ] || [ "$run_CollectTargetedPcrMetrics" == true ]; then
create_interval_file
fi

# if run_CollectMultipleMetrics is true
if [[ "$run_CollectMultipleMetrics" == true ]]; then
# Call Picard CollectMultipleMetrics
collect_multiple_metrics
fi

# if run_CollectHsMetrics is true
if [[ "$run_CollectHsMetrics" == true ]]; then
# Call Picard CollectHSMetrics
collect_hs_metrics
fi

# if run_CollectTargetedPcrMetrics is true
if [[ "$run_CollectTargetedPcrMetrics" == true ]]; then
# Call Picard CollectTargetedPcrMetrics
collect_targeted_pcr_metrics
fi

# if CollectRnaSeqMetrics is true
if [[ "$run_CollectRnaSeqMetrics" == true ]]; then
# use ref flat file if provided else convert gtf to refl flat from gtf
if [ -z "$ref_annot_refflat" ]; then # when there's NO refflat
	echo "create refflat file from gtf file in CTAT bundle"
	lib_dir=$(echo $fasta_index_name | cut -d "." -f 1,2)
	ref_annot_gtf="/home/dnanexus/${lib_dir}/ctat_genome_lib_build_dir/ref_annot.gtf"
	# conversion of gtf to ref flat file
	$java -jar ${pathToBin}/GtftoRefflat-assembly-0.1.jar \
	-g $ref_annot_gtf \
	-r ${lib_dir}_ref_annot.refflat
	ref_flat=${lib_dir}_ref_annot.refflat
else
	ref_flat=$ref_annot_refflat_path
fi
# Call Picard CollectRnaSeqMetrics
collect_rnaseq_metrics
fi

# Catch all false
if [[ "$run_CollectTargetedPcrMetrics" == false ]] && [[ "$run_CollectHsMetrics" == false ]] && [[ "$run_CollectMultipleMetrics" == false ]]; then
echo "No picard functions selected!"
fi

# ls $output_dir

ls .

##### CLEAN UP #####

# Upload all results files and directories in $HOME/out/eggd_picard_stats/
