process VERIFYBAMID
{
  tag "${reads[0]}, ${reads[1]}"
  debug true
  publishDir path:"${params.outdir}/verifybamID", mode:'copy'

  input:
    tuple val(sample_id), path(reads)
    val vcf_file

  output:
    path "*.depthSM"
    path "*.log"
    path "*.selfSM"

  script:
    """
    echo $vcf_file
    echo $reads
    bash nextflow-bin/code_verifybamid.sh $vcf_file ${reads[0]} ${reads[1]}
    """
}
