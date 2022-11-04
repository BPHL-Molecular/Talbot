process flcgsnp {
   input:
      val x
   output:
      //stdout
      val "${workflow.workDir}", emit: outputpath1
      
   """ 
   singularity exec docker://staphb/roary:3.12.0 roary -p ${params.threads} -i 90 -e --mafft --dont_delete_files -v -f ${params.output} ${params.input}/*.gff 
   singularity exec docker://staphb/snp-sites:2.3.3 snp-sites -o ${params.output}/SNPs.fasta -c ${params.output}/core_gene_alignment.aln
   singularity exec docker://staphb/snp-dists:0.6.2 snp-dists ${params.output}/core_gene_alignment.aln > ${params.output}/pairwise_matrix.tsv
   singularity exec docker://staphb/iqtree:1.6.7 iqtree -s ${params.output}/SNPs.fasta -m MFP+ASC -nt AUTO -bb 1000 -alrt 1000 -pre SNPs_boot -ntmax ${params.threads}
   """
}
