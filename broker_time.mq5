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
   
//--- Get the GMT time and calculate timezone offset in hours
   datetime gmtTime = TimeGMT();
   int timezoneOffset = (int)((serverTime - gmtTime) / 3600);
   string timezoneStr = StringFormat("GMT%+d", timezoneOffset);
   
//--- Convert time to string for display
   string timeString = TimeToString(serverTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   
//--- Combine time and timezone for display
   string displayString = StringFormat("Broker Server Time: %s %s", timeString, timezoneStr);
   
//--- Show broker's server time with timezone
   Comment(displayString);
   
//--- Print to Experts log as well
   Print(displayString);
  }
//+------------------------------------------------------------------+