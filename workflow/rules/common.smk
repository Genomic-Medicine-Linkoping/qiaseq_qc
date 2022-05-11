__author__ = "ljmesi"
__copyright__ = "Copyright 2022, ljmesi"
__email__ = "lauri.mesilaakso@regionostergotland.se"
__license__ = "GPL-3"

import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version

from hydra_genetics.utils.resources import load_resources
from hydra_genetics.utils.samples import *
from hydra_genetics.utils.units import *

min_version("6.10.0")

### Set and validate config file


configfile: "config/config.yaml"


validate(config, schema="../schemas/config.schema.yaml")
config = load_resources(config, config["resources"])
validate(config, schema="../schemas/resources.schema.yaml")


### Read and validate samples file

samples = pd.read_table(config["samples"], dtype=str).set_index("sample", drop=False)
validate(samples, schema="../schemas/samples.schema.yaml")

### Read and validate units file

units = pandas.read_table(config["units"], dtype=str).set_index(["sample", "type", "flowcell", "lane", "barcode"], drop=False).sort_index()
validate(units, schema="../schemas/units.schema.yaml")

### Set wildcard constraints


wildcard_constraints:
    barcode="[A-Z+]+",
    chr="[^_]+",
    flowcell="[A-Z0-9]+",
    lane="L[0-9]+",
    sample="|".join(get_samples(samples)),
    type="N|T|R"


def compile_result_file_list():
    files = [
        {"in": ["alignment/samtools_merge_bam",                ".bam"],                           "out": ["results/dna/bam", ".bam"]},
        {"in": ["alignment/samtools_merge_bam",                ".bam.bai"],                       "out": ["results/dna/bam", ".bam.bai"]},
        {"in": ["qc/picard_collect_duplication_metrics",       ".duplication_metrics.txt"],       "out": ["results/dna/qc",  ".duplication_metrics.txt"]},
        {"in": ["qc/picard_collect_hs_metrics",                ".HsMetrics.txt"],                 "out": ["results/dna/qc",  ".HsMetrics.txt"]},
        {"in": ["qc/picard_collect_alignment_summary_metrics", ".alignment_summary_metrics.txt"], "out": ["results/dna/qc",  ".alignment_summary_metrics.txt"]},
        {"in": ["qc/picard_collect_insert_size_metrics",       ".insert_size_metrics.txt"],       "out": ["results/dna/qc",  ".insert_size_metrics.txt"]},
        {"in": ["qc/samtools_stats",                           ".samtools-stats.txt"],            "out": ["results/dna/qc",  ".samtools-stats.txt"]},
        {"in": ["qc/mosdepth",                                 ".mosdepth.summary.txt"],          "out": ["results/dna/qc",  ".mosdepth.summary.txt"]},
        {"in": ["qc/mosdepth_bed" ,                            ".per-base.bed.gz"],               "out": ["results/dna/qc",  ".per-base.bed.gz"]},
        {"in": ["snv_indels/bcbio_variation_recall_ensemble",  ".ensembled.vcf.gz"],              "out": ["results/dna/vcf", ".ensembled.vcf.gz"]},
    ]
    input_files = [
        "%s/%s_%s%s" % (file_info["in"][0], sample, unit_type, file_info["in"][1])
        for file_info in files
        for sample in get_samples(samples)
        for unit_type in get_unit_types(units, sample)
    ]
    output_files = [
        "%s/%s_%s%s" % (file_info["out"][0], sample, unit_type, file_info["out"][1])
        for file_info in files
        for sample in get_samples(samples)
        for unit_type in get_unit_types(units, sample)
    ]
    input_files += [
        "qc/fastqc/%s_%s_%s.html" % (sample, t, read)
        for sample in get_samples(samples)
        for t in get_unit_types(units, sample)
        for read in ["fastq1", "fastq2"]
    ]
    output_files += [
        "results/dna/qc/%s_%s_%s.html" % (sample, t, read)
        for sample in get_samples(samples)
        for t in get_unit_types(units, sample)
        for read in ["fastq1", "fastq2"]
    ]
    output_files += [
        "results/dna/vcf/%s_%s_%s.vcf.gz" % (caller, sample, t)
        for caller in ["mutect2", "vardict"]
        for sample in get_samples(samples)
        for t in get_unit_types(units, sample)
    ]
    input_files += [
        "snv_indels/%s/%s_%s.merged.vcf.gz" % (caller, sample, t)
        for caller in ["mutect2", "vardict"]
        for sample in get_samples(samples)
        for t in get_unit_types(units, sample)
    ]
    input_files.append("qc/multiqc/multiQC.html")
    output_files.append("results/dna/qc/multiQC.html")
    return input_files, output_files


def compile_output_list(wildcards):
    input_files, output_files = compile_result_file_list()
    return output_files

# These are used by the final copy results rule
input_files, output_files = compile_result_file_list()
