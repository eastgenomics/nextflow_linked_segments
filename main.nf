nextflow.enable.dsl=2
//include all of the modules
include { TNHaplotyper2 } from './modules/TNHaplotyper2'
include { PICARDQC } from './modules/PICARDQC'
include { SAMTOOLS_FLAGSTAT } from './modules/SAMTOOLS_FLAGSTAT'
include { VERIFYBAMID } from './modules/VERIFYBAMID'
include { VCF_HANDLER } from './modules/VCF_HANDLER'


//run workflow
// from bam files, the QC steps and tnhHaplotyper should launch
// once tnhhaplotyper is done vcfhandler for uranus should launch


workflow{
    //create bam and bam.bai file pairs into nextflow channel
   bam_pairs = "$params.bam_path" + "/*.{bam,bam.bai}"
   bam_pairs_ch = channel.fromFilePairs("$bam_pairs")
    //run TNHaplotyper2 process from TNHaplotyper2 module
   mutec_path_ch = TNHaplotyper2(bam_pairs_ch, params.fasta_index_tar, params.gatkResource).tnhaplotyper2_vcf
    
    // picardQC

   PICARDQC(bam_pairs_ch, params.fasta_index_tar, params.bedfile, params.run_CollectMultipleMetrics, \
   params.run_CollectHsMetrics, params.run_CollectTargetedPcrMetrics, params.run_CollectRnaSeqMetrics, \
   params.ref_annot_refflat_path)

    // samtool

   SAMTOOLS_FLAGSTAT(bam_pairs_ch)

    // veriftbam ID can use vcfs produced by TNHaplotyper
   VERIFYBAMID(bam_pairs_ch, params.vcf_file)

    // vcf handler

   pindel_path = "$params.pindel_vcf_path" + "/*_vs_TA2_S59_L008_tumor.flagged.vcf.{gz,gz.tbi}"
   pindel_path_ch = channel.fromFilePairs( "$pindel_path" )

   vcf_pairs_ch = pindel_path_ch.combine(mutec_path_ch).groupTuple()
   vcf_pairs_ch.view()
   // combined_pindel_mutec_ch.view()

   // vcf_pairs_ch = combined_pindel_mutec_ch.groupTuple()
   // collect emited files from pindel
   // collect emited files from mutec2
   // make file pairs channel as below?
   // emit as tuples, combine and groupTuple using sample ID as key?

   // needs to be dx:// otherwise nextflow throws errors here for it not being a path
   // Cannot a find a file system provider for scheme: project-GkYP7j04F2bPqzq0q881gZk2
   // vcf_pairs_ch = channel.fromFilePairs( ["$mutec2_path", "$pindel_path"], size: -1)


   // run the tool
   VCF_HANDLER(vcf_pairs_ch, params.mutec2_bed, params.pindel_bed, params.mutec2_fasta, params.mutec2_fai, \
   params.vep_docker_image, params.vep_plugins, params.vep_refs, params.vep_annotation, params.maf_file, \
   params.maf_file_tbi, params.pindel_vcf_path, params.python_packages)
   }
