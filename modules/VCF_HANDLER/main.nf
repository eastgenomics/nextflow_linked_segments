process VCF_HANDLER
{
  tag "${sample_id}"
  // debug true
  publishDir  path:"${params.outdir}/VCF_handler_for_uranus", mode:'copy'
  errorStrategy 'finish'

// need to consider best error strategy - terminate (default) means if one task fails, the pipeline is immediately terminated
// finish means if a task fails the rest of the running taks will finish running, then the pipeline will terminate
// ignore means all tasks continue and then pipeline finishes successfully

  input:
    tuple val(sample_id), val(vcfs), path(haplotyper_vcf), path(haplotyper_vcf_tbi)
    val mutect2_bed
    val pindel_bed
    val mutect2_fasta
    val mutect2_fai
    val vep_docker_image
    val vep_plugins
    val vep_refs
    val vep_annotation
    val maf_file
    val maf_file_tbi
    val pindel_vcf_path
    val python_packages
  output:
    path "out/allgenes_filtered_vcf/*"
    path "out/bsvi_vcf/*"
    path "out/text_report/*"
    path "out/excel_report/*"
    path "out/pindel_vep_vcf/*"

// will need to see how the vcfs are passed to the process and sort how they are passed to nextflow code
// check files/inputs are of expected type
  script:
    pindel_vcf_tuple = vcfs[0]
    pindel_vcf = pindel_vcf_tuple[0]
    pindel_vcf_tbi = pindel_vcf_tuple[1]

//if more than one sample given for some reason the tuples have multiple duplicate entries
    haplotyper_vcf_first = haplotyper_vcf[0]
    haplotyper_vcf_tbi_first = haplotyper_vcf_tbi[0]
    """
    echo ${vcfs}

    echo "running tool"
    bash nextflow-bin/code_eggd_vcf_handler_for_uranus_nextflow.sh  $pindel_vcf $pindel_vcf_tbi $haplotyper_vcf_first $haplotyper_vcf_tbi_first $mutect2_bed $pindel_bed $mutect2_fasta $mutect2_fai $vep_docker_image "$vep_plugins" "$vep_refs" "$vep_annotation" $maf_file $maf_file_tbi $pindel_vcf_path "$python_packages"

    """
}
