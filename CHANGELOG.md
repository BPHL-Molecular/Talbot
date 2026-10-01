# Changelog

All notable changes to Talbot are documented in this file.

---

## [Unreleased]

### Pipeline modernization
One process per module, containers and resources in `nextflow.config`, submission through `talbot.sh`.

- `talbot.nf` is the entry point; `talbot.sh` submits it on SLURM with the `apptainer` profile.
- Modules: `roary`, `snp_sites`, `snp_dists`, `iqtree`.
- `params.output` holds `pairwise_matrix.tsv`, `core_snps.fasta` and `core_snps.treefile`; `roary/` holds `core_gene_alignment.aln`, `gene_presence_absence.csv` and `summary_statistics.txt`; `iqtree/` holds `.contree`, `.iqtree` and `.log`.
- `roary` runs with `-i 90 -e --mafft`.
- `nextflow.config` holds the `standard`, `docker`, `singularity` and `apptainer` profiles, the container and CPU/memory for each process, and the run record in `params.output/pipeline_info/`.
- `params.yaml` takes `input`, `output` and `pangenome`.
- The run stops before any task when `input` holds fewer than 4 GFF files, and the error asks for genomes of one species, ideally one sequence type or serotype.
- `snp_sites` fails with a clear message when the core alignment has no SNPs.

### Tool stack
- `pangenome` in `params.yaml` selects `roary` or `panaroo`; any other value, or a missing one, stops the run.
- `modules/panaroo.nf`: `--clean-mode strict --remove-invalid-genes -a core --aligner mafft`; downstream steps use `core_gene_alignment_filtered.aln`.
- Containers: Roary 3.13.0, Panaroo 1.8.0, snp-sites 2.5.1, snp-dists 1.2.0, IQ-TREE 3.1.3.
- IQ-TREE runs `-m MFP` with `-fconst` from `snp-sites -C` and `--seed 12345`.

### SNP report
- `bin/summary_report.py` (Python 3, standard library only) runs on the host through `modules/summary_report.nf`; `talbot.sh` loads the `python3` module.
- `summary_report.txt`: pangenome tool, genome count, core genes, core alignment length, SNP sites, min/max pairwise SNPs, best-fit model, SNP threshold, cluster count, samples flagged by core QC.
- `core_qc_report.txt`: per-sample percentage of the core alignment that is gaps or unknown bases; above 10% is `REVIEW`.
- `snp_threshold` in `params.yaml` (optional, no default) clusters samples by single linkage and writes `linkage_report.txt`: cluster ID, cluster size, closest sample(s), min SNPs, samples within the threshold. A value that is not a whole number of 0 or more stops the run.
- `summary_report.txt` `core_genome_qc`: `PASS`, or `UNRELIABLE` with the likely cause when there are fewer than 100 core genes.
- `panaroo` fails with a clear message when no gene is core.
- README "Reading the results": a checklist before sharing results and worked examples of low core genes, a distant sample and tool differences.
- `iqtree/core_snps.midpoint.treefile`: the ML tree rooted at its midpoint, support values kept on their bipartitions.
- Reports are UTF-16LE with a BOM and CRLF line endings; unreadable values are `No data`.
