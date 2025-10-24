import MetaTrader5 as mt5
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Initialize MT5 connection
if not mt5.initialize():
    print("MT5 initialize() failed")
    mt5.shutdown()
    exit()

# Define the time range for September 2025
start_date = datetime(2025, 9, 1)
end_date = datetime(2025, 9, 30, 23, 59, 59)

# Fetch historical data for EURUSD, H1 timeframe, for September 2025
rates = mt5.copy_rates_range("EURUSD", mt5.TIMEFRAME_H1, start_date, end_date)
if rates is None or len(rates) == 0:
    print("Failed to fetch historical data for September 2025")
    mt5.shutdown()
    exit()

df = pd.DataFrame(rates)
df['time'] = pd.to_datetime(df['time'], unit='s')

# Generate 30 random indices for trade signals
np.random.seed(42)  # For reproducibility
random_indices = np.random.choice(df.index, size=30, replace=False)
random_indices.sort()  # Sort to maintain chronological order

# Create random BUY/SELL signals
signals = np.random.choice(["BUY", "SELL"], size=30, p=[0.5, 0.5])

# Create a DataFrame for the signals
signal_data = pd.DataFrame({
    "timestamp": df.loc[random_indices, "time"].dt.strftime("%Y-%m-%d %H:%M:%S"),
    "signal": signals
})

# Save signals to CSV
output_file = "signals.csv"
signal_data.to_csv(output_file, mode="w", index=False, header=True)

print(f"Generated 30 random trade signals and saved to {output_file}")

# Shutdown MT5 connection
mt5.shutdown()