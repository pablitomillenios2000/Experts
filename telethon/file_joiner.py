import pandas as pd
import re
from pathlib import Path

# List of input CSV files
input_files = [
    "compro_NVDA_5d.csv",
    "compro_tsla_5d.csv",
    "vendo_NVDA_5d.csv",
    "vendo_tsla_5d.csv"
]

# Initialize an empty list to store dataframes
dfs = []

# Process each CSV file
for file in input_files:
    # Read the CSV
    df = pd.read_csv(file)
    
    # Remove timezone (+00:00) from date column
    df['date'] = df['date'].str.replace(r'\+00:00', '', regex=True)
    
    # Extract symbol from filename (NVDA or TSLA)
    symbol = file.split('_')[1].upper()
    
    # Determine direction based on filename (Compro -> BUY, Vendo -> SELL)
    direction = 'BUY' if file.startswith('compro') else 'SELL'
    
    # Extract price from text using regex
    df['price'] = df['text'].str.extract(r'(\d+\.\d{2})')[0].astype(float)
    
    # Create new columns for the output format
    df['msg'] = df['message_id']
    df['timestamp'] = df['date']
    df['symbol'] = symbol
    df['direction'] = direction
    
    # Select only the required columns
    df = df[['msg', 'timestamp', 'symbol', 'direction', 'price']]
    
    # Append to list of dataframes
    dfs.append(df)

# Concatenate all dataframes
combined_df = pd.concat(dfs, ignore_index=True)

# Sort by timestamp in ascending order
combined_df = combined_df.sort_values('timestamp')

# Save to output CSV
output_file = "trades_for_execution.csv"
combined_df.to_csv(output_file, index=False)

print(f"Output file '{output_file}' created successfully.")