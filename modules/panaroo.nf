process panaroo {
    tag "${gffs.size()} genomes"
    publishDir { "${params.output}" }, mode: 'copy'

    input:
        path gffs
    output:
        path "panaroo/core_gene_alignment_filtered.aln", emit: core_aln
        path "panaroo/gene_presence_absence.csv",        emit: presence_absence
        path "panaroo/summary_statistics.txt",           emit: summary

    script:
    """
    mkdir -p panaroo
    panaroo \\
        -i ${gffs} \\
        -o panaroo \\
        --clean-mode strict \\
        --remove-invalid-genes \\
        -a core --aligner mafft \\
        -t ${task.cpus}

    if [ ! -s panaroo/core_gene_alignment_filtered.aln ]; then
        echo "panaroo: no core genes found in all genomes; check for incomplete assemblies or mixed species" >&2
        exit 1
    fi
    """
}
