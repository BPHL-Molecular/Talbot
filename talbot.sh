#!/usr/bin/bash
#SBATCH --account=bphl-umbrella
#SBATCH --qos=bphl-umbrella
#SBATCH --job-name=talbot
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64gb
#SBATCH --time=48:00:00
#SBATCH --output=talbot.%j.out
#SBATCH --error=talbot.%j.err
#SBATCH --mail-user=your@email.gov
#SBATCH --mail-type=FAIL,END

module load apptainer nextflow python

# Path to container image cache directory
export NXF_APPTAINER_CACHEDIR=/path/to/apptainer/cache

# Plain text Nextflow log
export NXF_ANSI_LOG=false

nextflow run talbot.nf -profile apptainer -params-file params.yaml

# Rename output directory with timestamp
nxf_exit=$?
output_dir=$(grep '^output:' params.yaml | sed 's/output:[[:space:]]*//' | tr -d '"')
if [ $nxf_exit -eq 0 ] && [ -d "$output_dir" ]; then
    dt=$(date "+%Y%m%d%H%M%S")
    mv "$output_dir" "${output_dir}-${dt}"
elif [ $nxf_exit -ne 0 ]; then
    echo "Pipeline did not complete successfully." >&2
else
    echo "Pipeline exited 0 but output directory not found: $output_dir" >&2
fi
