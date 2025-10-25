import pandas as pd
from datetime import datetime
from alpaca.data.historical import StockHistoricalDataClient
from alpaca.data.requests import StockBarsRequest
from alpaca.data.timeframe import TimeFrame

# --------------------------------------
# CONFIGURATION
# --------------------------------------
API_KEY = ""
API_SECRET = ""

# Alpaca client
client = StockHistoricalDataClient(API_KEY, API_SECRET)

# Define symbol and time range
symbol = "QQQ"  # NASDAQ-100 ETF (tradable)
start_date = "2025-09-01"
end_date = "2025-09-30"

# --------------------------------------
# FETCH 1-MINUTE DATA (UTC)
# --------------------------------------
request_params = StockBarsRequest(
    symbol_or_symbols=symbol,
    timeframe=TimeFrame.Minute,
    start=pd.Timestamp(start_date, tz="UTC"),
    end=pd.Timestamp(end_date, tz="UTC")
)

bars = client.get_stock_bars(request_params)

# Convert to DataFrame
df = bars.df.copy().reset_index()

# Normalize timestamp column
if "timestamp" not in df.columns:
    if "index" in df.columns:
        df.rename(columns={"index": "timestamp"}, inplace=True)
    elif "time" in df.columns:
        df.rename(columns={"time": "timestamp"}, inplace=True)

# Filter by symbol (multi-symbol case)
if "symbol" in df.columns:
    df = df[df["symbol"] == symbol]

# Sort by timestamp
df = df.sort_values("timestamp").reset_index(drop=True)

# --------------------------------------
# CALCULATE 14-PERIOD RSI
# --------------------------------------
def compute_rsi(series, period=14):
    delta = series.diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.rolling(window=period, min_periods=period).mean()
    avg_loss = loss.rolling(window=period, min_periods=period).mean()
    rs = avg_gain / avg_loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

df["rsi_14"] = compute_rsi(df["close"])

# --------------------------------------
# SAVE RESULTS
# --------------------------------------
output_file = "QQQ_RSI_1m_Sep2025_UTC.csv"
df.to_csv(output_file, index=False)

# --------------------------------------
# DISPLAY SUMMARY
# --------------------------------------
print(f"✅ RSI computed for {len(df)} 1-minute bars of {symbol} from {start_date} to {end_date} (UTC)")
print(df[["timestamp", "close", "rsi_14"]].tail(10))
