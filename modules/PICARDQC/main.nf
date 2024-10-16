process PICARDQC {
    tag "${bam[0]}, ${bam[1]}"
    debug true
    publishDir params.outdir, mode:'copy'

    input:

      tuple val(sample_id), path(bam)
      val fasta_index
      val bedfile
      val run_CollectMultipleMetrics
      val run_CollectHsMetrics
      val run_CollectTargetedPcrMetrics
      val run_CollectRnaSeqMetrics
      val ref_annot_refflat_path

    output:

    // TODO: add when statements to have outputs for the differernt run types

    // change so only *.[name]
      path "*.alignment_summary_metrics", optional: true
      path "*.insert_size_metrics", optional: true
      path "*.insert_size_histogram.pdf", optional: true
      path "*.quality_distribution_metrics", optional: true
      path "*.quality_distribution.pdf", optional: true
      path "*.quality_by_cycle_metrics", optional: true
      path "*.quality_by_cycle.pdf", optional: true
      path "*.base_distribution_by_cycle_metrics", optional: true
      path "*.base_distribution_by_cycle.pdf", optional: true
      path "*.gc_bias.detail_metrics", optional: true
      path "*.gc_bias.summary_metrics", optional: true
      path "*.gc_bias.pdf", optional: true
      path "*.quality_yield_metrics", optional: true
      path "*.pertarget_coverage.tsv", optional: true
      path "*.hsmetrics.tsv", optional: true

    script:
    """
    echo $fasta_index
    echo $bedfile
    echo ${bam[0]}
    echo ${bam[1]}
    echo $run_CollectMultipleMetrics
    bash nextflow-bin/code_picardQC.sh $fasta_index $bedfile ${bam[0]} ${bam[1]} $run_CollectMultipleMetrics $run_CollectHsMetrics $run_CollectTargetedPcrMetrics $run_CollectRnaSeqMetrics $ref_annot_refflat_path
    """


}
