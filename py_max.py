import os
import pandas as pd

# Define the terminal prefix path
terminal_prefix = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\"

# File path for nvda_1m.csv
file_path = os.path.join(terminal_prefix, "nvda_1m.csv")

# Output file path
output_path = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\local_maxima.csv"

# Read the input CSV
df = pd.read_csv(file_path)

# List to hold local maxima
local_maxima = []

# Loop through the dataframe, skipping the first 2 and last 2 rows
for i in range(2, len(df) - 2):
    current_high = df.at[i, 'High']
    is_local_max = True
    for j in [i-2, i-1, i+1, i+2]:
        if current_high <= df.at[j, 'High']:
            is_local_max = False
            break
    if is_local_max:
        local_maxima.append({
            'date time': df.at[i, 'Timestamp'],
            'maximum': current_high
        })

# Create output dataframe and write to CSV
if local_maxima:
    out_df = pd.DataFrame(local_maxima)
    out_df.to_csv(output_path, index=False)
else:
    # Write empty CSV with header
    pd.DataFrame(columns=['date time', 'maximum']).to_csv(output_path, index=False)