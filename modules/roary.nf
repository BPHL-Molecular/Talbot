process roary {
    tag "${gffs.size()} genomes"
    publishDir { "${params.output}" }, mode: 'copy'

    input:
        path gffs
    output:
        path "roary/core_gene_alignment.aln", emit: core_aln
        path "roary/",                        emit: results

    script:
    """
    roary \\
        -p ${task.cpus} \\
        -i 90 \\
        -e --mafft \\
        -f roary \\
        ${gffs}
    """
}
