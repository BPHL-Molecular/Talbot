#!/usr/bin/env nextflow

/*
  Talbot Pipeline
  Florida's BPHL Nextflow pipeline for bacterial core genome SNP phylogeny
  Email: bphl-sebioinformatics@flhealth.gov
*/

nextflow.enable.dsl = 2

include { roary }     from './modules/roary.nf'
include { snp_sites } from './modules/snp_sites.nf'
include { snp_dists } from './modules/snp_dists.nf'
include { iqtree }    from './modules/iqtree.nf'

workflow {
    log.info """
    Talbot - Bacterial Core Genome SNP Phylogeny Pipeline
    ==========================================================================
    input dir   : ${params.input}
    output dir  : ${params.output}
    ==========================================================================
    """

    def n_gffs = files("${params.input}/*.gff").size()
    if ( n_gffs < 4 )
        error "Talbot needs at least 4 GFF files in ${params.input}, found ${n_gffs}. " +
              "Use genomes of a single species, ideally sharing a sequence type or serotype: " +
              "the tree and SNP distances are meant for relatedness and outbreak investigation."

    ch_gffs = channel.fromPath("${params.input}/*.gff").collect()

    ch_roary = roary(ch_gffs)
    ch_snps  = snp_sites(ch_roary.core_aln)
    snp_dists(ch_roary.core_aln)
    ch_tree  = iqtree(ch_snps.snps)

    ch_tree.tree
        .subscribe { tree ->
            def taxa = tree.text.count(',') + 1
            log.info "genomes submitted: ${n_gffs}, taxa in tree: ${taxa}, " +
                     "run record: ${params.output}/pipeline_info/"
            if ( taxa != n_gffs )
                log.warn "tree has ${taxa} taxa but ${n_gffs} GFF files were submitted"
        }
}
