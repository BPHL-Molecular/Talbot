<p align="center">
  <em>⚠️ For research use only. Results were obtained by procedures that were not CLIA validated.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Nextflow-≥23.04-brightgreen?style=plastic&logo=nextflow" />
  <img src="https://img.shields.io/badge/License-MIT-red?style=plastic" />
</p>

## 🦠🌳 Overview

Talbot is Florida BPHL's Nextflow pipeline for bacterial core genome SNP phylogeny. It is the downstream step after [Sanibel](https://github.com/BPHL-Molecular/Sanibel): it takes the Prokka GFF files Sanibel writes for each sample, builds a pangenome with Roary or Panaroo, extracts the core genome SNPs, computes pairwise SNP distances and infers a maximum likelihood tree with IQ-TREE.

Talbot is built for relatedness and outbreak investigation, so all genomes in a run should be the same species and, ideally, share a sequence type or serotype. A pangenome across species or genera has almost no core genes, and the resulting tree is not meaningful.

### ⚙️ Dependencies

- **Nextflow** 23.04 to 26.x - [installation guide](https://github.com/nextflow-io/nextflow)
- **Apptainer/Singularity** - [installation guide](https://apptainer.org/docs/user/latest/)
- **Python** 3.10+ - [installation guide](https://docs.python.org/3/using/index.html)
- **SLURM** workload manager (required for HiPerGator; otherwise not required)

All bioinformatics tools run inside containers. The report script in `bin/` runs on the host with python3.

### 🛠️ Setup

#### 1. Clone this repository and enter the repository directory

```bash
$ git clone https://github.com/BPHL-Molecular/Talbot
$ cd Talbot/
```

#### 2. Collect the GFF files

Talbot needs at least 4 Prokka GFF3 files with the `##FASTA` section at the end, which is what Prokka writes by default. Sanibel publishes one per sample at `<sanibel_output>/<sample>/assembly/prokka/<sample>.gff`:

```bash
$ mkdir -p /full/path/to/gffs
$ cp /full/path/to/sanibel_output/*/assembly/prokka/*.gff /full/path/to/gffs/
```

Copy only the samples you want in the tree.

#### 3. Python

HiPerGator users can skip this step: `talbot.sh` loads Python with `module load python3`. Everyone else needs `python3` on the PATH when Nextflow runs, for example from a conda environment:

```bash
$ conda create -n talbot -c conda-forge python=3.10
$ conda activate talbot
```

#### 4. Configure params.yaml

```yaml
# Input / Output absolute paths, no trailing slash "/"
input:  "/full/path/to/gffs"
output: "/full/path/to/output"

# Pangenome tool: "roary" or "panaroo"
pangenome: "roary"

# Optional: group closely related samples into clusters and generate a linkage_report.txt
# Set a number of SNPs (e.g. 5): samples this close or closer are grouped together, or leave null to skip clustering
snp_threshold: null
```

#### SNP clusters

Set `snp_threshold` in `params.yaml` to group samples into clusters and write `linkage_report.txt`. Two samples join the same cluster when they are "N" SNPs (set by `snp_threshold`) apart or closer, and clusters chain: if A is close to B and B is close to C, all three share a cluster even when A and C are further apart. Clusters are numbered by size, largest first, and samples with no partner are `Unclustered`. With `snp_threshold: null` Talbot skips the clustering and writes no linkage report.

There is no default threshold on purpose. SNP cutoffs for relatedness depend on the species, the genome region compared and the epidemiology, so choose one that fits the organism and confirm clusters with epidemiological data.

#### Core genome QC

`core_qc_report.txt` gives, for each sample, the percentage of the core gene alignment that is gaps or unknown bases. A sample above 10% is marked `REVIEW`. A fragmented or contaminated assembly misses core genes, which shrinks the core genome for every sample in the run, so consider removing flagged samples and rerunning.

#### 5. Configure talbot.sh

Add your email address for job notifications and set `NXF_APPTAINER_CACHEDIR` to your image cache directory:

```bash
#SBATCH --mail-user=your@email.gov
export NXF_APPTAINER_CACHEDIR=/path/to/apptainer/cache
```

### 🐊 HiPerGator Usage
```bash
sbatch talbot.sh
```

### ⚡ Local Usage
```bash
nextflow run talbot.nf -profile apptainer -params-file params.yaml
```

### Pangenome tool

Set `pangenome` in `params.yaml` to `"roary"` or `"panaroo"`. Roary is the shipped setting, so results stay comparable with earlier Talbot runs.

Panaroo corrects for annotation errors from fragmented assemblies, contamination and misassemblies ([Tonkin-Hill et al. 2020](https://doi.org/10.1186/s13059-020-02090-4)). Talbot runs it in strict mode and uses its filtered core alignment, which drops high-entropy genes. SNP distances from the two tools can differ, so compare runs made with the same tool.

### Workflow Diagram

```mermaid
flowchart LR
    IN[Prokka GFFs] --> PAN["Pangenome<br/>Roary or Panaroo"]
    PAN --> SNP["Core SNPs<br/>snp-sites"]
    PAN --> DIST["Pairwise distances<br/>snp-dists"]
    SNP --> TREE["ML tree<br/>IQ-TREE"]
    DIST --> REP["summary_report<br/>summary · core QC · clusters · midpoint tree"]
    TREE --> REP

    style REP fill:#f96,stroke:#333,color:#000
```

### 🧩 Modules

Talbot is made possible thanks to the following tools:

[Roary](https://github.com/sanger-pathogens/Roary) · [Panaroo](https://github.com/gtonkinhill/panaroo) · [snp-sites](https://github.com/sanger-pathogens/snp-sites) · [snp-dists](https://github.com/tseemann/snp-dists) · [IQ-TREE](https://github.com/iqtree/iqtree3)

### 📁 Output

All results are written to `params.output/`:

| Path | Contents |
|------|----------|
| `summary_report.txt` | One row per run: pangenome tool, genomes, core genes, core alignment length, SNP sites, min/max pairwise SNPs, IQ-TREE best-fit model, SNP threshold, number of clusters, samples flagged by core QC |
| `core_qc_report.txt` | One row per sample: percentage of the core alignment missing, `PASS` or `REVIEW` |
| `linkage_report.txt` | Only when `snp_threshold` is set. One row per sample: cluster ID, cluster size, closest sample(s), min SNPs, number of samples within the threshold |
| `pairwise_matrix.tsv` | Pairwise SNP distances over the core gene alignment |
| `core_snps.fasta` | Variable sites of the core gene alignment |
| `core_snps.treefile` | Maximum likelihood tree, UFBoot and SH-aLRT support (1000 replicates each) |
| `roary/` | Roary pangenome (`pangenome: "roary"`): `core_gene_alignment.aln`, `gene_presence_absence.csv`, `summary_statistics.txt` |
| `panaroo/` | Panaroo pangenome (`pangenome: "panaroo"`): `core_gene_alignment_filtered.aln`, `gene_presence_absence.csv`, `summary_statistics.txt` |
| `iqtree/core_snps.midpoint.treefile` | The ML tree rooted at its midpoint, with the same support values, for viewing in iTOL or Microreact |
| `iqtree/core_snps.contree` | UFBoot consensus tree |
| `iqtree/core_snps.iqtree` | IQ-TREE report, including the best-fit model |
| `iqtree/core_snps.log` | IQ-TREE run log |
| `pipeline_info/` | Nextflow run record: `trace.txt`, `execution_report.html`, `timeline.html` |

### 📧 Contact
**Email**: bphl-sebioinformatics@flhealth.gov

### ⚖️ License
Talbot is licensed under the [MIT License](LICENSE).
