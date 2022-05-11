.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "env.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = qiaseq_qc
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 92
ARGS = --notemp #--keep-incomplete #--forceall

.PHONY: \
create_inputs \
run \
create_module \
update_env \
hydra_help \
picard_interval_list \
report \
help


SAMPLE_DATA = \
samples.tsv \
units.tsv

FASTQ_INPUT_DIR = fastqs
MAIN_SMK = workflow/Snakefile

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	export SINGULARITY_LOCALCACHEDIR=/data/Twist_DNA_Solid/cache_dir
	snakemake --cores $(CPUS) \
	--rerun-incomplete \
	--use-singularity \
	--singularity-args "--bind /data/" \
	-s $(MAIN_SMK) \
	$(ARGS)

## create_module: Create module to start up the project
create_module:
	$(CONDA_ACTIVATE)
	hydra-genetics create-module \
    --name qiaseq_qc \
    --description "Qc of Qiagen's pipeline" \
    --author "ljmesi" \
    --git-user ljmesi


## create_inputs: Create input metadata files based on files residing in a given fastq-file directory
create_inputs:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files \
	-d $(FASTQ_INPUT_DIR) \
	--force

## update_env: Update conda environment to the latest version defined by env.yml file
update_env:
	$(ACTIVATE_CONDA)
	mamba env update --file env.yml

## hydra_help: Produce help message for hydra-genetics utility
hydra_help:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files --help

## picard_interval_list: Create interval list from bed file for use with picard metrics tools
picard_interval_list:
	$(CONDA_ACTIVATE)
	picard BedToIntervalList \
    I=/home/lauri/Desktop/qiagen_qc/ref/QIAseq_DNA_panel.CDHS-42409Z-9864.roi.bed \
    O=/home/lauri/Desktop/qiagen_qc/ref/QIAseq_DNA_panel.CDHS-42409Z-9864.roi.interval_list \
    SD=/data/Twist_DNA/BWA_0.7.10_refseq/hg19.with.mt.fasta

## report: Make snakemake report
report:
	$(CONDA_ACTIVATE)
	snakemake -j 1 --report $(REPORT) -s $(MAIN_SMK)

## help: Show this message
help:
	@grep '^##' ./Makefile
