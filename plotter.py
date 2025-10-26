import pandas as pd
import mplfinance as mpf
import os

# Define the terminal prefix path
terminal_prefix = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\"

# File path for nvda_1m.csv
file_path = os.path.join(terminal_prefix, "nvda_1m.csv")

# Read the CSV file
try:
    df = pd.read_csv(file_path, parse_dates=['Timestamp'])
except FileNotFoundError:
    print(f"Error: File {file_path} not found.")
    exit(1)
except Exception as e:
    print(f"Error reading CSV file: {e}")
    exit(1)

# Ensure the Timestamp column is in datetime format
df['Timestamp'] = pd.to_datetime(df['Timestamp'], format='%Y.%m.%d %H:%M:%S')

# Set Timestamp as the index
df.set_index('Timestamp', inplace=True)

# Rename 'TickVolume' to 'Volume' for mplfinance compatibility
df = df.rename(columns={'TickVolume': 'Volume'})

# Select the last 10 candles
last_10_candles = df.tail(10)

# Check if there are enough candles
if len(last_10_candles) < 1:
    print("Error: Not enough data to plot.")
    exit(1)

# Plot the candlestick chart
mpf.plot(last_10_candles, 
         type='candle', 
         title='NVDA Last 10 Candles (1-Minute)', 
         style='yahoo', 
         ylabel='Price (USD)', 
         volume=True, 
         ylabel_lower='Volume (Tick)')