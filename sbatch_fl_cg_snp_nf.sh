#!/usr/bin/bash
#SBATCH --account=bphl-umbrella
#SBATCH --qos=bphl-umbrella
#SBATCH --job-name=nextseq_fastq_nextflow
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20                    #This parameter shoulbe be equal to the number of samples if you want fastest running speed. However, the setting number should be less than the max cpu limit(150). 
#SBATCH --mem=20gb
#SBATCH --time=48:00:00
#SBATCH --output=flaq_amr_nf.%j.out
#SBATCH --error=flaq_amr_nf.%j.err


nextflow run fl_cg_snp.nf -params-file params.yaml > x.txt
workid="$(grep -o -m 1 '\[.*/.*\]' x.txt | cut -d ' ' -f 1 | cut -d '[' -f 2 | cut -d ']' -f 1)" 
w2="$(realpath ./work/$workid*)"
cp -r $w2/* ./output
rm x.txt
#singularity cache clean -f 
