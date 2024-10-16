process TNHaplotyper2
{
    debug true
    publishDir '.', mode:'copy'
    tag "${reads[0]}, ${reads[1]}"
    //input ref files
    input:
        tuple val(sample_id), path(reads)
        val fasta_index_tar
        val gatkResource
    //output vcf and index files
    output:
        path "*_markdup_recalibrated_tnhaplotyper2.vcf.{gz,gz.tbi}",emit:tnhaplotyper2_vcf
    //running bash scripts from bin folder for sentieon tnhaplotyper2
    script:
        """
        echo "Running ${reads[0]} ${reads[1]}"
        bash nextflow-bin/code_tnhaplotyper2.sh $fasta_index_tar $gatkResource ${reads[0]} ${reads[1]}
        """
}
