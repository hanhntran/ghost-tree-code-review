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

### 4. COMMANDS
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
head ./files/sh_general_release_dynamic_19.02.2025_taxonomy.txt
```

```
'Abrothallus_subhalei|MT153946|SH1227328.10FU|refs'	k__Fungi;p__Ascomycota;c__Dothideomycetes;o__Abrothallales;f__Abrothallaceae;g__Abrothallus;s__Abrothallus_subhalei
'Mucor_inaequisporus|JN206177|SH1227742.10FU|refs'	k__Fungi;p__Mucoromycota;c__Mucoromycetes;o__Mucorales;f__Mucoraceae;g__Mucor;s__Mucor_inaequisporus
'Candida_vrieseae|KY102517|SH1232203.10FU|refs'	k__Fungi;p__Ascomycota;c__Saccharomycetes;o__Saccharomycetales;f__Saccharomycetales_fam_Incertae_sedis;g__Candida;s__Candida_vrieseae
'Exophiala_lecanii-corni|AY857528|SH1233462.10FU|refs'	k__Fungi;p__Ascomycota;c__Eurotiomycetes;o__Chaetothyriales;f__Herpotrichiellaceae;g__Exophiala;
```

2. Prepare the Backbone Tree (SILVA)
- Goal: extract fungal sequences from SILVA and filter highly variable positions to create a stable backbone tree

    2a. Extract fungal sequences only
```
ghost-tree silva extract-fungi \
    SILVA_132_SSURef_Nr99_tax_silva_full_align_trunc.fasta \
    tax_slv_ssu_132.acc_taxid \
    tax_slv_ssu_132.txt silva_fungi_only.txt
```
-
    2b. Filter highly variable positions 

```
# Parameters: 
#   0.9 (Maximum Gap Frequency): Positions with >90% gaps are removed.
#   0.8 (Maximum Composition Entropy): Highly variable positions removed.

ghost-tree filter-alignment-positions \
    silva_fungi_only.txt \
    0.9 0.8 \
    silva_fungi_only_filtered.txt
```

3. Group Extensions (OTUs)
- Goal: cluster ITS sequences based on similarity to map them to the backbone tree.
```
zcat group-extensions sh_general_release_dynamic_19.02.2025.fasta.gz \
| ghost-tree extensions 0.1 ITS_otu_map_10.txt
```

4. Convert CONSTAX taxonomy to ghost-tree format similar to the silva taxonomic map
```
# Input and Output files
INPUT_FILE="files/constax_taxonomy.txt"
OUTPUT_FILE="files/constax_taxonomy_qiime2_format.txt"

# Use awk to process the file line by line
# -F'\t': Sets input delimiter to tab
# OFS='\t': Sets output delimiter to tab

awk -F'\t' 'BEGIN { OFS="\t" }
    # NR > 1: Skip the header line (matches pandas read_csv behavior)
    NR > 1 {
        # --- 1. Handle the Index/OTU ID (Column 1) ---
        # Add single quotes around the ID
        id = "\x27" $1 "\x27"

        # --- 2. Build the Taxonomy String (Columns 2 to 8) ---
        taxonomy = ""
        
        # Loop through columns 2 (Kingdom) to 8 (Species)
        for (i = 2; i <= 8; i++) {
            val = $i
            
            # Map column index to QIIME2 prefix
            if (i==2) prefix="k__"
            else if (i==3) prefix="p__"
            else if (i==4) prefix="c__"
            else if (i==5) prefix="o__"
            else if (i==6) prefix="f__"
            else if (i==7) prefix="g__"
            else if (i==8) prefix="s__"

            # Check if value is empty (matches fillna(""))
            if (val == "" || val == "NaN") {
                segment = prefix
            } else {
                # Clean the value:
                
                # 1. Trim leading/trailing whitespace (val.strip())
                gsub(/^ +| +$/, "", val)
                
                # 2. Remove "_1" suffix (val.replace("_1", ""))
                gsub(/_1/, "", val)

                # 3. Species-specific logic (Column 8)
                if (i == 8) {
                    # Split by space and take the last part (parts[-1])
                    len = split(val, parts, " ")
                    if (len > 0) val = parts[len]
                }

                # 4. Replace remaining spaces with underscores
                gsub(/ /, "_", val)

                segment = prefix val
            }

            # Append to the growing taxonomy string with semicolon
            if (i == 2) {
                taxonomy = segment
            } else {
                taxonomy = taxonomy ";" segment
            }
        }

        # Print final line: quoted_ID [tab] taxonomy_string
        print id, taxonomy

    }' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Done. Formatted taxonomy saved to $OUTPUT_FILE"
```


5. Scaffold the Hybrid Tree
- Goal: graft the ITS OTU sequences onto the filtered Silva backbone tree
