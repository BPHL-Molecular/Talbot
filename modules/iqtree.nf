process iqtree {
    tag "core_snps"
    publishDir { "${params.output}" },        mode: 'copy', pattern: 'core_snps.treefile'
    publishDir { "${params.output}/iqtree" }, mode: 'copy', pattern: 'core_snps.{contree,iqtree,log}'

    input:
        path snps
        path fconst
    output:
        path "core_snps.treefile",             emit: tree
        path "core_snps.iqtree",               emit: report
        path "core_snps.{contree,iqtree,log}", emit: results

    script:
    """
    iqtree3 \\
        -s ${snps} \\
        -m MFP \\
        -fconst \$(cat ${fconst}) \\
        -B 1000 -alrt 1000 \\
        -T ${task.cpus} \\
        --seed 12345 \\
        --prefix core_snps
    """
}
