# mutect2_nextflow
The applet to call mosaic variants and generate vcf files using sentieon TNHaplotyper2. 
The inputs for the applet are bam files and index files.
It ouputs the zipped vcf and index files in the output folder named `mutect2_output`
### nextflow.config
Contains all parameters for mutect2 
### main.nf
Calls the module and runs the workflow
### modules
Contains module for mutect2 
### bin folder
Contains the source code, sentieon package (sentieon-genomics-202112.07) and sentieon licence
### To build mutect2_nextflow on DNAnexus
```
 git clone <repo>
 dx select <DNAnexus project>
 dx build --nextflow (inside the cloned folder)
 ```
### To run mutect2_nextflow on DNAnexus
 ```
 dx run applet-XXXXX \
-inextflow_pipeline_params="--file_path=<dir/to/bam files>" 
```
