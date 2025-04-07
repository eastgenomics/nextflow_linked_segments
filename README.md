# Uranus_workflow_segments_nextflow

This nextflow pipeline can be called to run the following segments of the Uranus pipeline
- TNHaplotyper
- PicardQC
- Samtools Flagstat
- VerifyBAMID
- VCF_Handler_For_Uranus

The required inputs are the bam and index files produced by sention_bwa and vcf files produced by cgppindel
The tool outputs

### nextflow.config
Contains all parameters for the modules TNHaplotyper, PicardQC, Samtools Flagstat, VerifyBAMID, VCF_Handler_For_Uranus
### main.nf
Calls the modules, sorts channels,  and runs the workflow
### modules
Contains module for TNHaplotyper, PicardQC, Samtools Flagstat, VerifyBAMID, VCF_Handler_For_Uranus
### bin folder
Contains the source code, sentieon package (sentieon-genomics-202010.02) and sentieon licence, 
### To build mutect2_nextflow on DNAnexus
```
 git clone <repo>
 dx select <DNAnexus project>
 dx build --nextflow (inside the cloned folder)
 ```
 The output to the command line of dx build will included as the applet ID for running the nextflow command
 The ID for the tested version is applet-GzQj5p04FzqVgQ6yX7QYBVjy
### To run Uranus_workflow_segments_nextflow on DNAnexus
 ```
 dx run applet-GzQj5p04FzqVgQ6yX7QYBVjy -inextflow_pipeline_params="--pindel_vcf_path=dx://project-xxx:[path/to/pindel/vcfs] --bam_path=dx://project-xxx:[path/to/bams]"
 # Example
 dx run applet-GzQj5p04FzqVgQ6yX7QYBVjy -inextflow_pipeline_params="--pindel_vcf_path=dx://project-GqFKf584FzqQzv1Y5Jj51gyp:/inputs/pindel --bam_path=dx://project-GqFKf584FzqQzv1Y5Jj51gyp:/inputs/bams"

```
