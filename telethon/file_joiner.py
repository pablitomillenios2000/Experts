import pandas as pd
import re
from pathlib import Path

# List of input CSV files
input_files = [
    "compro_NVDA_5d.csv",
    "compro_tsla_5d.csv",
    "Vendo_NVDA_5d.csv",
    "vendo_tsla_5d.csv"
]

# Initialize an empty list to store dataframes
dfs = []

# Process each CSV file
for file in input_files:
    # Read the CSV
    df = pd.read_csv(file)
    
    # Remove timezone (+00:00) from date column if present
    df['date'] = df['date'].str.replace(r'\+00:00', '', regex=True)
    
    # Determine direction based on filename (compro -> BUY, vendo -> SELL)
    direction = 'BUY' if file.lower().startswith('compro') else 'SELL'
    
    # Extract symbol from text: look for NVDA or TSLA
    def extract_symbol(text):
        if 'NVDA' in text.upper():
            return 'NVDA'
        elif 'TSLA' in text.upper():
            return 'TSLA'
        else:
            return None  # Symbol not found
    
    df['symbol'] = df['text'].apply(extract_symbol)
    
    # Extract price from text: look for patterns like 123,45$ or 123.45$
    def extract_price(text):
        match = re.search(r'(\d+[.,]\d{2})\$', text)
        if match:
            price_str = match.group(1).replace(',', '.')  # Normalize to dot for float
            return float(price_str)
        return 'NULL'  # Return string "NULL" if price not found
    
    df['price'] = df['text'].apply(extract_price)
    
    # Create new columns for the output format
    df['msg'] = df['message_id']
    df['timestamp'] = df['date']
    df['direction'] = direction
    
    # Drop rows where symbol couldn't be extracted
    df = df.dropna(subset=['symbol'])
    
    # Select only the required columns
    df = df[['msg', 'timestamp', 'symbol', 'direction', 'price']]
    
    # Append to list of dataframes
    dfs.append(df)

# Concatenate all dataframes
combined_df = pd.concat(dfs, ignore_index=True)

# Sort by timestamp in ascending order
combined_df = combined_df.sort_values('timestamp')

# Save to output CSV with na_rep='NULL' to ensure NULL is written for any NaN values
output_file = "trades_for_execution.csv"
combined_df.to_csv(output_file, index=False, na_rep='NULL')

print(f"Output file '{output_file}' created successfully.")