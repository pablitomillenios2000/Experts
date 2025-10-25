import MetaTrader5 as mt5
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Initialize MT5 connection
if not mt5.initialize():
    print("MT5 initialize() failed")
    mt5.shutdown()
    exit()

terminal_prefix = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files"
rsi1tesla_file = "1mrsitesla.csv"
rsi5tesla_file = "5mrsitesla.csv"
stochtesla_file = "1mstochtsla.csv"
rsi1ndqusd_file = "1mrsindxusd.csv"


# Define the time range for October 2025
start_date = datetime(2025, 9, 1)
end_date = datetime(2025, 9, 30, 23, 59, 59)

# Fetch historical data for TSLA, M1 timeframe
rates_m1_tsla = mt5.copy_rates_range("TSLA", mt5.TIMEFRAME_M1, start_date, end_date)
if rates_m1_tsla is None or len(rates_m1_tsla) == 0:
    print("Failed to fetch 1-minute historical data for TSLA for October 2025")
    mt5.shutdown()
    exit()

# Fetch historical data for TSLA, M5 timeframe
rates_m5_tsla = mt5.copy_rates_range("TSLA", mt5.TIMEFRAME_M5, start_date, end_date)
if rates_m5_tsla is None or len(rates_m5_tsla) == 0:
    print("Failed to fetch 5-minute historical data for TSLA for October 2025")
    mt5.shutdown()
    exit()

# Fetch historical data for NDXUSD, M1 timeframe
rates_m1_ndx = mt5.copy_rates_range("NDXUSD", mt5.TIMEFRAME_M1, start_date, end_date)
if rates_m1_ndx is None or len(rates_m1_ndx) == 0:
    print("Failed to fetch 1-minute historical data for NDXUSD for October 2025")
    mt5.shutdown()
    exit()

# Create DataFrames
df_m1_tsla = pd.DataFrame(rates_m1_tsla)
df_m1_tsla['time'] = pd.to_datetime(df_m1_tsla['time'], unit='s')
df_m5_tsla = pd.DataFrame(rates_m5_tsla)
df_m5_tsla['time'] = pd.to_datetime(df_m5_tsla['time'], unit='s')
df_m1_ndx = pd.DataFrame(rates_m1_ndx)
df_m1_ndx['time'] = pd.to_datetime(df_m1_ndx['time'], unit='s')

# Calculate RSI (14-period) for all data
def calculate_rsi(data, periods=14):
    delta = data['close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=periods).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=periods).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

df_m1_tsla['rsi'] = calculate_rsi(df_m1_tsla)
df_m5_tsla['rsi'] = calculate_rsi(df_m5_tsla)
df_m1_ndx['rsi'] = calculate_rsi(df_m1_ndx)

# Calculate Stochastic Oscillator (14, 3, 3) for TSLA M1
def calculate_stochastic(df, k_period=14, d_period=3, smooth=3):
    df['lowest_low'] = df['low'].rolling(window=k_period).min()
    df['highest_high'] = df['high'].rolling(window=k_period).max()
    df['%K'] = 100 * (df['close'] - df['lowest_low']) / (df['highest_high'] - df['lowest_low'])
    df['%K_smooth'] = df['%K'].rolling(window=smooth).mean()
    df['%D'] = df['%K_smooth'].rolling(window=d_period).mean()
    return df

df_m1_tsla = calculate_stochastic(df_m1_tsla)

# Align 5-minute TSLA RSI and 1-minute NDXUSD RSI with 1-minute TSLA data
df_m1_tsla = df_m1_tsla.merge(
    df_m5_tsla[['time', 'rsi']].rename(columns={'rsi': 'rsi_m5'}),
    left_on='time',
    right_on='time',
    how='left'
).merge(
    df_m1_ndx[['time', 'rsi']].rename(columns={'rsi': 'rsi_ndx'}),
    left_on='time',
    right_on='time',
    how='left'
)
# Forward-fill to align data
df_m1_tsla['rsi_m5'] = df_m1_tsla['rsi_m5'].ffill()
df_m1_tsla['rsi_ndx'] = df_m1_tsla['rsi_ndx'].ffill()

# Generate BUY signals (RSI M1 TSLA < 30, RSI M5 TSLA < 35, RSI M1 NDXUSD < 30) with rule: no new BUY until previous SELL
signal_list = []
potential_buys = df_m1_tsla[
    (df_m1_tsla['rsi'] < 30) & 
    (df_m1_tsla['rsi_m5'] < 35) & 
    (df_m1_tsla['rsi_ndx'] < 30)
][['time', 'rsi', 'rsi_m5', 'rsi_ndx', '%K_smooth']].copy()
potential_buys['signal'] = 'BUY'
last_sell_time = start_date - timedelta(minutes=1)  # Initialize to allow first BUY

for idx, buy in potential_buys.iterrows():
    buy_time = buy['time']
    if buy_time > last_sell_time:  # Only allow BUY if after last SELL
        buy_dict = {
            'time': buy_time,
            'signal': 'BUY',
            'rsi': buy['rsi'],
            'rsi_m5': buy['rsi_m5'],
            'rsi_ndx': buy['rsi_ndx'],
            '%K_smooth': buy['%K_smooth']
        }
        signal_list.append(buy_dict)
        
        # Find corresponding SELL signal
        cutoff_time = buy_time.replace(hour=19, minute=0, second=0, microsecond=0)
        if cutoff_time < buy_time:
            cutoff_time += timedelta(days=1)
        
        sell_window = df_m1_tsla[(df_m1_tsla['time'] > buy_time) & (df_m1_tsla['time'] <= cutoff_time)]
        sell_candidates = sell_window[sell_window['%K_smooth'] > 80]
        
        if not sell_candidates.empty:
            sell_row = sell_candidates.iloc[0]
            sell_time = sell_row['time']
            sell_k = sell_row['%K_smooth']
            sell_rsi = sell_row['rsi']
            sell_rsi_m5 = sell_row['rsi_m5']
            sell_rsi_ndx = sell_row['rsi_ndx']
        else:
            sell_time = cutoff_time
            closest_mask = df_m1_tsla['time'] <= sell_time
            if closest_mask.any():
                closest_data = df_m1_tsla[closest_mask].iloc[-1]
                sell_k = closest_data['%K_smooth']
                sell_rsi = closest_data['rsi']
                sell_rsi_m5 = closest_data['rsi_m5']
                sell_rsi_ndx = closest_data['rsi_ndx']
            else:
                sell_k = np.nan
                sell_rsi = np.nan
                sell_rsi_m5 = np.nan
                sell_rsi_ndx = np.nan
        
        sell_dict = {
            'time': sell_time,
            'signal': 'SELL',
            'rsi': sell_rsi,
            'rsi_m5': sell_rsi_m5,
            'rsi_ndx': sell_rsi_ndx,
            '%K_smooth': sell_k
        }
        signal_list.append(sell_dict)
        
        last_sell_time = sell_time  # Update last SELL time to block new BUYs

# Convert to DataFrame
signal_data = pd.DataFrame(signal_list)
signal_data['timestamp'] = signal_data['time'].dt.strftime("%Y-%m-%d %H:%M:%S")

# Filter out SELL signals outside the data range
max_time = df_m1_tsla['time'].max()
signal_data['time_check'] = pd.to_datetime(signal_data['timestamp'], format="%Y-%m-%d %H:%M:%S")
signal_data = signal_data[signal_data['time_check'] <= max_time]
signal_data = signal_data[['timestamp', 'signal', 'rsi', 'rsi_m5', 'rsi_ndx', '%K_smooth']]  # Include RSI and %K_smooth

# Create DataFrame for tv.csv with timestamps adjusted by -3.5 hours
signal_data_tv = signal_data[['timestamp', 'signal', 'rsi', 'rsi_m5', 'rsi_ndx', '%K_smooth']].copy()
signal_data_tv['timestamp'] = (
    pd.to_datetime(signal_data_tv['timestamp'], format="%Y-%m-%d %H:%M:%S") - timedelta(hours=3.5)
).dt.strftime("%Y-%m-%d %H:%M:%S")

# Save signals to CSV
tester_prefix = "C:\\Users\\Pablo\\AppData\\Roaming\\MetaQuotes\\Tester\\D0E8209F77C8CF37AD8BF550E51FF075\\Agent-127.0.0.1-3000\\MQL5\\Files\\"
output_file = tester_prefix + "signals.csv"
output_file2 = "./signals.csv.back"
output_file_tv = "./tv.csv"

signal_data.to_csv(output_file, mode="w", index=False, header=True)
signal_data.to_csv(output_file2, mode="w", index=False, header=True)
signal_data_tv.to_csv(output_file_tv, mode="w", index=False, header=True)

print(f"Generated {len(signal_data[signal_data['signal'] == 'BUY'])} BUY signals (RSI M1 TSLA < 30, RSI M5 TSLA < 35, RSI M1 NDXUSD < 30) with corresponding SELL signals (%K > 80 or at 19:00) and saved to {output_file} and {output_file_tv} with RSI and %K_smooth values")

# Shutdown MT5 connection
mt5.shutdown()