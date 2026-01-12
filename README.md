# ghost-tree-code-review

Description: This pipeline generates a hybrid phylogenetic tree for fungal ITS sequences. It grafts the ITS OTUs onto a pre-computed SILVA 18S backbone tree using the `ghost-tree` tool.

### 1. ENVIRONMENT AND DEPENDENCIES
```
# Environment setup
conda create -n ghost-tree-test 

conda activate ghost-tree-test 

conda install bioconda::ghost-tree 

conda install conda-forge::python=3.10 conda-forge::matplotlib=3.10.7 
```

### 2. INPUT FILES
A. Backbone Database (Reference)
- SILVA_132_SSURef_Nr99_tax_silva_full_align_trunc.fasta.gz
(Source: SILVA database, pre-aligned 18S sequences)

B. Extension Database (UNITE + input ITS sequences)
- sh_general_release_dynamic_19.02.2025.fasta.gz
(Source: UNITE database, raw fasta)
- ITS2_centroids_97.fasta
(Source: Our experiment's clustered OTUs)

C. Taxonomy maps
- constax_taxonomy_qiime2_format.txt
(Source: Consensus taxonomy output from CONSTAX pipeline. Used in final step
for better resolution than raw UNITE headers.)

### 3. DOWNLOAD DATABASES
#### Silva database
```
# Silva database (current version v132)
wget https://www.arb-silva.de/current-release/Exports/SILVA_138.2_SSURef_NR99_tax_silva_full_align_trunc.fasta.gz

# Silva database taxid file
wget https://www.arb-silva.de/current-release/Exports/taxonomy/tax_slv_ssu_138.2.acc_taxid.gz
gunzip tax_slv_ssu_138.2.acc_taxid.gz

wget https://www.arb-silva.de/current-release/Exports/taxonomy/tax_slv_ssu_138.2.txt.gz
gunzip tax_slv_ssu_138.2.txt.gz
```
#### UNITE database
UNITE database (current version 19.02.2025) sh_general_release_dynamic_all_19.02.2025.fasta.gz from
https://doi.plutof.ut.ee/doi/10.15156/BIO/3301229

### 4. PIPELINE COMMANDS
1.  Pre-processing UNITE Headers
- Goal: convert UNITE headers into a tab-separated Accession/Taxonomy map
- Note: this step handles raw UNITE data.
```
zcat sh_general_release_dynamic_19.02.2025.fasta.gz \
| grep ">" \
| tr -d '>' \
| awk -F'\|k__' '{print $1 "|k__" $2}' \
| awk -F'\|k__' '{print "'"'"'" $1 "'"'"'" "\t" "k__" $2}' \
> sh_general_release_dynamic_19.02.2025_taxonomy.txt
```

```
head ./ghost-tree-code-review/sh_general_release_dynamic_19.02.2025_taxonomy.txt
```
[unite_headers](pics/unite_headers.png)
