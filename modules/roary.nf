process roary {
    tag "${gffs.size()} genomes"
    publishDir { "${params.output}" }, mode: 'copy'

    input:
        path gffs
    output:
        path "roary/core_gene_alignment.aln",   emit: core_aln
        path "roary/gene_presence_absence.csv", emit: presence_absence
        path "roary/summary_statistics.txt",    emit: summary

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
