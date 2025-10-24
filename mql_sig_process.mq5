//+------------------------------------------------------------------+
//|                                                 SignalTrader.mq5 |
//|                        Copyright 2025, xAI                       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

struct Signal {
   datetime time;
   string type;
};

Signal signals[];
int signalCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Hardcode signals
   signalCount = 2;
   ArrayResize(signals, signalCount);
   
   signals[0].time = StringToTime("2025.10.02 09:40:00");
   signals[0].type = "BUY";
   signals[1].time = StringToTime("2025.10.14 09:40:00");
   signals[1].type = "SELL";

   // Verify signal times
   for (int i = 0; i < signalCount; i++) {
      if (signals[i].time == 0) {
         Print("Invalid datetime for signal ", i);
         return(INIT_FAILED);
      }
   }

   // Sort signals by time (already sorted, but included for robustness)
   for (int i = 0; i < signalCount - 1; i++) {
      for (int j = i + 1; j < signalCount; j++) {
         if (signals[i].time > signals[j].time) {
            Signal temp = signals[i];
            signals[i] = signals[j];
            signals[j] = temp;
         }
      }
   }

   Print("Loaded ", signalCount, " hardcoded signals.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Nothing to do
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   static int currentIndex = 0;
   datetime now = TimeCurrent();

   if (currentIndex >= signalCount) return;

   if (now >= signals[currentIndex].time) {
      CTrade trade;
      double lotSize = 0.01; // Small lot size for testing; adjust as needed
      ENUM_ORDER_TYPE orderType = (signals[currentIndex].type == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      // Open position (assuming hedging mode; if netting, you may need to close previous)
      if (trade.PositionOpen(_Symbol, orderType, lotSize, 0, 0, 0)) {
         Print("Opened ", signals[currentIndex].type, " at ", TimeToString(signals[currentIndex].time));
      } else {
         Print("Failed to open ", signals[currentIndex].type, " Error: ", trade.ResultRetcode());
      }

      currentIndex++;
   }
}
//+------------------------------------------------------------------+