#!/bin/bash 
#SBATCH --time=48:00:00
#SBATCH --nodes=1 
#SBATCH --ntasks=24 
#SBATCH --partition open
#SBATCH --job-name=ghost-tree-OTUs
#SBATCH --mem=250GB 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hnt001@bucknell.edu

# Get started
# echo "Job started on $(hostname) at $(date)"

cd $(pwd)

module load anaconda

source activate ghost-tree

# enable pipefail: if any command in a pipeline fails, the entire script will fail
set -o pipefail

################################################################################
# Input and Output files
SILVA_DB_ALIGN="SILVA_132_SSURef_Nr99_tax_silva_full_align_trunc.fasta.gz"
UNITE_DB="sh_general_release_dynamic_19.02.2025.fasta.gz"
UNITE_TAX_FILE="sh_general_release_dynamic_19.02.2025_taxonomy.txt"
SILVA_TAX_MAP="tax_slv_ssu_132.txt"
SILVA_TAX_ACC_TAXID="tax_slv_ssu_132.acc_taxid"
SILVA_FUNGI_ONLY_FILE="silva_fungi_only.txt"
SILVA_FUNGI_ONLY_FILTERED_FILE="silva_fungi_only_filtered.txt"
ITS_OTU_MAP_10_FILE="ITS_otu_map_10.txt"
CONSTAX_TAX_FILE="constax_taxonomy.txt"
CONSTAX_TAX_GHOSTTREE_FILE="constax_taxonomy_ghosttree_format.txt"
ITS2_FILE="ITS2_centroids_97_sorted_cleaned_headers.fasta"
GHOST_TREE_OUT="ghost_tree_10"
################################################################################
# 1. Convert the CONSTAX taxonomy file to GhostTree format
# The CONSTAX taxonomy file is in the format of: <OTU> <Kingdom_1> <Phylum_1> <Class_1> <Order_1> <Family_1> <Genus_1> <Species_1>
# need to convert it to the format of ghosttree format:
# 'OTU'	k__Fungi;p__Ascomycota;c__Dothideomycetes;o__Abrothallales;f__Abrothallaceae;g__Abrothallus;s__Abrothallus_subhalei
echo "Converting the CONSTAX taxonomy file to GhostTree format"
python3 scripts/constax_to_ghosttree_format.py $CONSTAX_TAX_FILE $CONSTAX_TAX_GHOSTTREE_FILE
echo "Done"

# 2. Build the CONSTAX taxonomy file for the UNITE database
# create a tab delimited file with the UNITE headers 
# expected format: <accession> <taxonomy>
# example format: 'Abrothallus_subhalei|MT153946|SH1227328.10FU|refs'	k__Fungi;p__Ascomycota;c__Dothideomycetes;o__Abrothallales;f__Abrothallaceae;g__Abrothallus;s__Abrothallus_subhalei
echo "Building the CONSTAX taxonomy file for the UNITE database"
zcat $UNITE_DB \
    | grep ">" \
    | tr -d '>' \
    | awk -F'\|k__' '{print $1 "|k__" $2}' \
    | awk -F'\|k__' '{print "'"'"'" $1 "'"'"'" "\t" "k__" $2}' \
    > $UNITE_TAX_FILE 
echo "Done"

echo "Extracting the SILVA database for the fungi only"
ghost-tree silva extract-fungi \
    $SILVA_DB_ALIGN \
    $SILVA_TAX_ACC_TAXID \
    $SILVA_TAX_MAP \
    $SILVA_FUNGI_ONLY_FILE 
echo "Done"

echo "Filtering the SILVA database for the fungi only"
ghost-tree filter-alignment-positions \
    $SILVA_FUNGI_ONLY_FILE \
    0.9 0.8 \
    $SILVA_FUNGI_ONLY_FILTERED_FILE 
echo "Done"

echo "Grouping the UNITE database extensions"
zcat $UNITE_DB \
| ghost-tree extensions group-extensions 0.1 $ITS_OTU_MAP_10_FILE
> $UNITE_DB_EXTENSIONS_FILE
echo "Done"

echo "Scaffolding the GhostTree"
ghost-tree scaffold hybrid-tree-foundation-alignment \
    $ITS_OTU_MAP_10_FILE \
    $CONSTAX_TAX_GHOSTTREE_FILE  \
    $ITS2_FILE \
    $SILVA_FUNGI_ONLY_FILTERED_FILE \
    $GHOST_TREE_OUT
echo "Done"
