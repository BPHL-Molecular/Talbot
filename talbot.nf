#!/usr/bin/env nextflow

/*
  Talbot Pipeline
  Florida's BPHL Nextflow pipeline for bacterial core genome SNP phylogeny
  Email: bphl-sebioinformatics@flhealth.gov
*/

nextflow.enable.dsl = 2

include { roary }          from './modules/roary.nf'
include { panaroo }        from './modules/panaroo.nf'
include { snp_sites }      from './modules/snp_sites.nf'
include { snp_dists }      from './modules/snp_dists.nf'
include { iqtree }         from './modules/iqtree.nf'
include { summary_report } from './modules/summary_report.nf'

workflow {
    log.info """
    Talbot - Bacterial Core Genome SNP Phylogeny Pipeline
    ==========================================================================
    input dir   : ${params.input}
    output dir  : ${params.output}
    pangenome   : ${params.pangenome}
    snp thresh  : ${params.snp_threshold != null ? params.snp_threshold : 'not set'}
    ==========================================================================
    """

    if ( !(params.pangenome in ['roary', 'panaroo']) )
        error "pangenome must be roary or panaroo, got ${params.pangenome}"

    if ( params.snp_threshold != null && !(params.snp_threshold instanceof Integer && params.snp_threshold >= 0) )
        error "snp_threshold must be a whole number of SNPs (0 or more), got ${params.snp_threshold}"

    def n_gffs = files("${params.input}/*.gff").size()
    if ( n_gffs < 4 )
        error "Talbot needs at least 4 GFF files in ${params.input}, found ${n_gffs}. " +
              "Use genomes of a single species, ideally sharing a sequence type or serotype: " +
              "the tree and SNP distances are meant for relatedness and outbreak investigation."

    ch_gffs = channel.fromPath("${params.input}/*.gff").collect()

    ch_pan   = params.pangenome == 'panaroo' ? panaroo(ch_gffs) : roary(ch_gffs)
    ch_snps  = snp_sites(ch_pan.core_aln)
    ch_dists = snp_dists(ch_pan.core_aln)
    ch_tree  = iqtree(ch_snps.snps, ch_snps.fconst)

    summary_report(
        ch_dists.matrix,
        ch_pan.summary,
        ch_pan.core_aln,
        ch_snps.snps,
        ch_tree.report,
        ch_tree.tree
    )

    ch_tree.tree
        .subscribe { tree ->
            def taxa = tree.text.count(',') + 1
            log.info "genomes submitted: ${n_gffs}, taxa in tree: ${taxa}, " +
                     "run record: ${params.output}/pipeline_info/"
            if ( taxa != n_gffs )
                log.warn "tree has ${taxa} taxa but ${n_gffs} GFF files were submitted"
        }
}
