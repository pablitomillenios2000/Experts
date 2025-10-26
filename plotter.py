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

# Define the end time for the candles
end_time = pd.to_datetime('2025.09.30 19:30:00', format='%Y.%m.%d %H:%M:%S')

# Select the last 10 candles ending at end_time
last_10_candles = df[df.index <= end_time].tail(10)

# Check if there are enough candles
if len(last_10_candles) < 1:
    print(f"Error: No data available up to {end_time}.")
    exit(1)
elif len(last_10_candles) < 10:
    print(f"Warning: Only {len(last_10_candles)} candles available up to {end_time}.")

# Plot the candlestick chart without volume
mpf.plot(last_10_candles, 
         type='candle', 
         title='NVDA Last 10 Candles (1-Minute) Ending 2025.09.30 19:30', 
         style='yahoo', 
         ylabel='Price (USD)')