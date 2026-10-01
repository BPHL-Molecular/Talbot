process iqtree {
    tag "core_snps"
    publishDir { "${params.output}/iqtree" }, mode: 'copy'

    input:
        path snps
    output:
        path "core_snps.treefile",             emit: tree
        path "core_snps.{contree,iqtree,log}", emit: results

    script:
    """
    iqtree \\
        -s ${snps} \\
        -m MFP+ASC \\
        -bb 1000 -alrt 1000 \\
        -nt AUTO -ntmax ${task.cpus} \\
        -pre core_snps
    """
}
