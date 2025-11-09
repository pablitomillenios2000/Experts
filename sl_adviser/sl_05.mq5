//+------------------------------------------------------------------+
//|                                       DrawStopLine_Testable.mq5 |
//|                                Works even when market is closed |
//+------------------------------------------------------------------+
#property strict

input color   LineColor   = clrPurple;   // Line color
input int     LineWidth   = 3;           // Line width
input double  LineOffsetP = 0.5;         // Line offset percent (below buy price)

string LineName = "BuyStopLine";
bool testMode = true;  // set to true to draw without a real buy

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("EA initialized. Drawing test line...");
   DrawTestLine(); // <-- draw immediately on start
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Draws the test line (for weekends or no ticks)                   |
//+------------------------------------------------------------------+
void DrawTestLine()
  {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // if market closed, fallback to last known tick
   if(price <= 0)
     price = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

   double linePrice = price * (1.0 - LineOffsetP / 100.0);

   if(ObjectFind(0, LineName) != 0)
     {
      ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, linePrice);
      ObjectSetInteger(0, LineName, OBJPROP_COLOR, LineColor);
      ObjectSetInteger(0, LineName, OBJPROP_WIDTH, LineWidth);
      PrintFormat("Line created at %.5f (%.2f%% below %.5f)", linePrice, LineOffsetP, price);
     }
   else
     {
      ObjectSetDouble(0, LineName, OBJPROP_PRICE, linePrice);
     }
  }

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(testMode)
     {
      DrawTestLine(); // keep updating during market hours
      return;
     }

   // Normal live-trade logic here if needed
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0, LineName);
   Print("EA deinitialized — line removed.");
  }
//+------------------------------------------------------------------+
