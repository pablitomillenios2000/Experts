## Modus Operandi

1) mql_sig_process does the trading
2) It can only trade if there is a signals.csv with BUY SELL signals

3) py_sig_gen generates those signals but it can only do so if the RSIs are available

4) readout_stats must be run in the first place to generate the RSIs

