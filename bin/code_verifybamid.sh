#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

### for local testing remove need to download
echo "running script"

vcf_file="$1"
input_bam="$2"
input_bam_bai="$3"
pathToBin="nextflow-bin"
nameOfSample=${input_bam%%.*}

# get file names
vcf_file=$(echo ${vcf_file}| sed 's|dx://||g')
vcf_file_name=$(dx describe ${vcf_file} --name)

# download files
dx download "$vcf_file" -o "$vcf_file_name"

# Create output directory
mkdir ./verifybamid_out

export VERIFYBAMID_BIN=${pathToBin}/verifyBamID

# Call verifyBamID for contamination check. The following notable options are passed:
# --ignoreRG; to check the contamination for the entire BAM rather than examining individual read groups
# --precise; calculate the likelihood in log-scale for high-depth data (recommended when --maxDepth is greater than 20)
# --maxDepth 1000; For the targeted exome sequencing, --maxDepth 1000 and --precise is recommended.
$VERIFYBAMID_BIN --vcf ${vcf_file_name} --bam ${input_bam} --bai ${input_bam_bai} --ignoreRG --precise --maxDepth 1000 --out verifybamid_out

# move outputs to name of sample
mv verifybamid_out.depthSM ${nameOfSample}.depthSM
mv verifybamid_out.selfSM ${nameOfSample}.selfSM
mv verifybamid_out.log ${nameOfSample}.log
