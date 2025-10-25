//+------------------------------------------------------------------+
//|                                              BrokerTimeDisplay.mq5 |
//|                        Copyright 2025, Your Name                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- Get the current server time
   datetime serverTime = TimeCurrent();
   
//--- Convert to string for display
   string timeString = TimeToString(serverTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   
//--- Show broker's server time
   Comment("Broker Server Time: ", timeString);
   
//--- Print to Experts log as well
   Print("Current Broker Server Time: ", timeString);
  }
//+------------------------------------------------------------------+