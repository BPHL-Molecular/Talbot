# Talbot
A Nextflow pipeline for pan genome analyses including phylogenic tree. The pipeline is a upgraded version of the pipeline fl_cg_snp. 

## Prerequisites
Nextflow should be installed. The detail of installation can be found in https://github.com/nextflow-io/nextflow.

Python3 is needed.

Singularity is also needed. The detail of installation can be found in https://singularity-tutorial.github.io/01-installation/.

## How to run
1. put your gff files into directory /gffs. Test data can be found in the directory /gffs/testdata. If you want to use the test data, copy them to the directory /gffs.
2. open file "parames.yaml", set the parameters. 
3. get into the top of the pipeline directory, run "sbatch sbatch_fl_cg_snp_nf.sh"

## Results
All results can be found in the directory /output.

