process snp_sites {
    tag "core_snps"
    publishDir { "${params.output}/snp_sites" }, mode: 'copy'

    input:
        path core_aln
    output:
        path "core_snps.fasta", emit: snps

    script:
    """
    snp-sites -c -o core_snps.fasta ${core_aln}

    if ! grep -v '^>' core_snps.fasta 2>/dev/null | grep -q .; then
        echo "snp_sites: no core SNPs in ${core_aln}, the genomes are identical or share no core genes" >&2
        exit 1
    fi
    """
}
