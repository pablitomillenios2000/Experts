![alt text](./img/image.png)

[Modus Operandi](./Funktionsweise.MD)

Trading Hours in Noctorial for TSLA (Nasdaq) are
Between 
13:30 and 19:59 Mo-Fr

The trades timestamps have to fall between those hours

In Trading View regular NVDA trading hours are between
9:30 and 16:00 Mo-Fr


to convert from TV to MT5 add +3.5 hours


SOLUTION: Set TV to UTC
The servers are in UTC (Noctorial)


=================

## Timeline:

1) Create a simple algo that buys at rsi <30 and sells at stochastic K>80
2) Compare the time points in TV and MT5

3) Backtest the algo
4) If it works complete the algo without Levels

5) Backtest
6) If it works create a realtime signal generator
7) Add a realtime signal consume

8) Add a short-trader

## Algo Conditions

1) RSI 14, 5m Oversold < 35
2) RSI 14 , 1m Oversold < 30
3) Stoch-K > 80
4) IXIC =>, 1m RSI14 Oversold <30