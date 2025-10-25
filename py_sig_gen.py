import MetaTrader5 as mt5
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Initialize MT5 connection
if not mt5.initialize():
    print("MT5 initialize() failed")
    mt5.shutdown()
    exit()

# Define the time range for October 2025
start_date = datetime(2025, 10, 1)
end_date = datetime(2025, 10, 23, 23, 59, 59)

# Fetch historical data for TSLA, M1 timeframe
rates = mt5.copy_rates_range("TSLA", mt5.TIMEFRAME_M1, start_date, end_date)
if rates is None or len(rates) == 0:
    print("Failed to fetch historical data for TSLA for October 2025")
    mt5.shutdown()
    exit()

# Create DataFrame
df = pd.DataFrame(rates)
df['time'] = pd.to_datetime(df['time'], unit='s')

# Calculate RSI (14-period)
def calculate_rsi(data, periods=14):
    delta = data['close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=periods).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=periods).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

df['rsi'] = calculate_rsi(df)

# Identify BUY signals (RSI < 30)
buy_signals = df[df['rsi'] < 30][['time']].copy()
buy_signals['signal'] = 'BUY'

# Create corresponding SELL signals (1 hour after each BUY)
sell_signals = buy_signals.copy()
sell_signals['time'] = sell_signals['time'] + timedelta(hours=1)
sell_signals['signal'] = 'SELL'

# Pair BUY and SELL signals to maintain order
paired_signals = []
for i in range(len(buy_signals)):
    paired_signals.append(buy_signals.iloc[i:i+1][['time', 'signal']])
    paired_signals.append(sell_signals.iloc[i:i+1][['time', 'signal']])

# Combine paired signals into a single DataFrame
signal_data = pd.concat(paired_signals).reset_index(drop=True)
signal_data['timestamp'] = signal_data['time'].dt.strftime("%Y-%m-%d %H:%M:%S")

# Filter out SELL signals that fall outside the available data range
max_time = df['time'].max()
signal_data['time'] = pd.to_datetime(signal_data['timestamp'])
signal_data = signal_data[signal_data['time'] <= max_time]
signal_data = signal_data[['timestamp', 'signal']]  # Keep only required columns

# Save signals to CSV
output_file = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Tester\\D0E8209F77C8CF37AD8BF550E51FF075\\Agent-127.0.0.1-3000\\MQL5\\Files\\signals.csv"
output_file2 = "./signals.csv.back"

signal_data.to_csv(output_file, mode="w", index=False, header=True)
signal_data.to_csv(output_file2, mode="w", index=False, header=True)

print(f"Generated {len(buy_signals)} BUY signals (RSI < 30) with corresponding SELL signals 1 hour later and saved to {output_file}")

# Shutdown MT5 connection
mt5.shutdown()