process summary_report {
    tag "summary"
    publishDir { "${params.output}" },        mode: 'copy', pattern: '*.txt'
    publishDir { "${params.output}/iqtree" }, mode: 'copy', pattern: '*.midpoint.treefile'

    input:
        path matrix
        path summary
        path core_aln
        path snps
        path iqtree_report
        path tree
    output:
        path "summary_report.txt",          emit: summary
        path "core_qc_report.txt",          emit: core_qc
        path "linkage_report.txt",          emit: linkage, optional: true
        path "core_snps.midpoint.treefile", emit: midpoint_tree

    script:
    def threshold = params.snp_threshold != null ? "--snp-threshold ${params.snp_threshold}" : ''
    """
    summary_report.py \\
        --matrix    ${matrix} \\
        --summary   ${summary} \\
        --core-aln  ${core_aln} \\
        --snps      ${snps} \\
        --iqtree    ${iqtree_report} \\
        --tree      ${tree} \\
        --pangenome ${params.pangenome} \\
        ${threshold}
    """
}
