#!/bin/bash 
#SBATCH --time=48:00:00
#SBATCH --nodes=1 
#SBATCH --ntasks=24 
#SBATCH --partition open
#SBATCH --job-name=Hershey_mycobiome
#SBATCH --mem=250GB 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hnt001@bucknell.edu

# Get started
# echo "Job started on $(hostname) at $(date)"

cd $(pwd)

# Set the trace
#set -uex

module load anaconda

source activate ghost-tree


#grep ">" sh_general_release_dynamic_19.02.2025.fasta | tr -d '>' | awk -F'\\|k__' '{print $1 "|k__" $2}' | awk -F'\\|k__' '{print "'"'"'" $1 "'"'"'" "\t" "k__" $2}' > sh_general_release_dynamic_19.02.2025_taxonomy.txt

#ghost-tree silva extract-fungi SILVA_132_SSURef_Nr99_tax_silva_full_align_trunc.fasta tax_slv_ssu_132.acc_taxid tax_slv_ssu_132.txt silva_fungi_only.txt

#ghost-tree filter-alignment-positions silva_fungi_only.txt 0.9 0.8 silva_fungi_only_filtered.txt

#ghost-tree extensions group-extensions sh_general_release_dynamic_19.02.2025.fasta 0.8 ITS_otu_map_80.txt

#ghost-tree scaffold hybrid-tree-foundation-alignment ITS_otu_map_80.txt sh_general_release_dynamic_19.02.2025_taxonomy.txt sh_general_release_dynamic_19.02.2025.fasta silva_fungi_only_filtered.txt ghost_tree_80

ghost-tree scaffold hybrid-tree-foundation-alignment ITS_otu_map_10.txt constax_taxonomy_qiime2_format.txt  ITS2_centroids_97_sorted_cleaned_headers.fasta silva_fungi_only_138.2_filtered.fasta ghost_tree_10
