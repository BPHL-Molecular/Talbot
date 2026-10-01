# Changelog

All notable changes to Talbot are documented in this file.

---

## [Unreleased]

### Pipeline modernization
One process per module, containers and resources in `nextflow.config`, submission through `talbot.sh`.

- `talbot.nf` is the entry point; `talbot.sh` submits it on SLURM with the `apptainer` profile.
- Modules: `roary`, `snp_sites`, `snp_dists`, `iqtree`, each publishing to its own directory under `params.output`.
- Published files: Roary `core_gene_alignment.aln`, `gene_presence_absence.csv` and `summary_statistics.txt`; IQ-TREE `.treefile`, `.contree`, `.iqtree` and `.log`.
- `roary` runs with `-i 90 -e --mafft`.
- `nextflow.config` holds the `standard`, `docker`, `singularity` and `apptainer` profiles, the container and CPU/memory for each process, and the run record in `params.output/pipeline_info/`.
- `params.yaml` takes `input`, `output` and optionally `pangenome`.
- The run stops before any task when `input` holds fewer than 4 GFF files, and the error asks for genomes of one species, ideally one sequence type or serotype.
- `snp_sites` fails with a clear message when the core alignment has no SNPs.

### Tool stack
- `pangenome` param selects `roary` (default) or `panaroo`; any other value stops the run.
- `modules/panaroo.nf`: `--clean-mode strict --remove-invalid-genes -a core --aligner mafft`; downstream steps use `core_gene_alignment_filtered.aln`.
- Containers: Roary 3.13.0, Panaroo 1.8.0, snp-sites 2.5.1, snp-dists 1.2.0, IQ-TREE 3.1.3.
- IQ-TREE runs `-m MFP` with `-fconst` from `snp-sites -C` and `--seed 12345`.
