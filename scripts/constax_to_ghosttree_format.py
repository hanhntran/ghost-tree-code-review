import pandas as pd
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

# Load input
df = pd.read_csv(input_file, sep="\t", index_col=0)

# Fill NaNs with empty string
df = df.fillna("")

# Column order expected for ghost-tree
ghosttree_levels = ['k__', 'p__', 'c__', 'o__', 'f__', 'g__', 's__']
taxonomy_cols = df.columns[0:7]  # first 7 columns are Domain to Species

# Remove _1 suffix and build taxonomy string
def format_tax(row):
    cleaned = []
    for i in range(7):
        val = row[taxonomy_cols[i]]
        prefix = ghosttree_levels[i]
        if val:
            val = val.strip().replace("_1", "")
            if i == 6:  # species level
                parts = val.split()
                val = parts[-1] if parts else ""
            val = val.replace(" ", "_")
            cleaned.append(prefix + val)
        else:
            cleaned.append(prefix)
    return ";".join(cleaned)

df = df.apply(format_tax, axis=1)

# Add single quotes around OTU IDs (index)
df.index = "'" + df.index.astype(str) + "'"

# Output file
df.to_csv(output_file, sep="\t", index=True, header=False)
