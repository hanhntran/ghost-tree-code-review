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
- SILVA_132_SSURef_Nr99_tax_silva_full_align_trunc.fasta
(Source: SILVA database, pre-aligned 18S sequences)

B. Extension Database (UNITE + input ITS data)
- sh_general_release_dynamic_19.02.2025.fasta
(Source: UNITE database, raw fasta)
- ITS2_centroids_97.fasta
(Source: Our experiment's clustered OTUS)

C. Taxonomy maps
- constax_taxonomy_qiime2_format.txt
(Source: Consensus taxonomy output from CONSTAX pipeline. Used in final step
for better resolution than raw UNITE headers.)

### 3. DOWNLOAD DATABASES
```
# Silva database (current version v132)
wget https://www.arb-silva.de/current-release/Exports/SILVA_138.2_SSURef_NR99_tax_silva_full_align_trunc.fasta.gz

# Silva database taxid file
wget https://www.arb-silva.de/current-release/Exports/taxonomy/tax_slv_ssu_138.2.acc_taxid.gz
gunzip tax_slv_ssu_138.2.acc_taxid.gz

wget https://www.arb-silva.de/current-release/Exports/taxonomy/tax_slv_ssu_138.2.txt.gz
gunzip tax_slv_ssu_138.2.txt.gz
```
