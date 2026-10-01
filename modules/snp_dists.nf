process snp_dists {
    tag "pairwise"
    publishDir { "${params.output}" }, mode: 'copy'

    input:
        path core_aln
    output:
        path "pairwise_matrix.tsv", emit: matrix

    script:
    """
    snp-dists ${core_aln} > pairwise_matrix.tsv
    """
}
