import MetaTrader5 as mt5
import pandas as pd
from datetime import datetime

# Initialize MT5 connection
if not mt5.initialize():
    print("MT5 initialize() failed")
    mt5.shutdown()

# Fetch historical data (e.g., EURUSD, last 1000 bars on H1)
rates = mt5.copy_rates_from_pos("EURUSD", mt5.TIMEFRAME_H1, 0, 1000)
df = pd.DataFrame(rates)
df['ma'] = df['close'].rolling(window=20).mean()  # Simple MA crossover strategy

# Generate signal (example: BUY if close > MA)
latest = df.iloc[-1]
signal = "BUY" if latest['close'] > latest['ma'] else "SELL"

# Save signal to CSV with timestamp
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
signal_data = pd.DataFrame([{"timestamp": timestamp, "signal": signal}])
signal_data.to_csv("signals.csv", mode="a", index=False, header=not pd.io.common.file_exists("signals.csv"))

mt5.shutdown()