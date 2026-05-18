//+------------------------------------------------------------------+
//|                                       DrawStopLine_Testable.mq5 |
//|                               Works even when market is closed |
//+------------------------------------------------------------------+
#property strict

// Include the trade position info library for easier position tracking
#include <Trade\PositionInfo.mqh>
CPositionInfo  m_position; // Position info object

input color    LineColor   = clrPurple;   // Line color
input int      LineWidth   = 3;           // Line width
input double   LineOffsetP = 0.5;         // Line offset percent (below buy price)

string LineName = "BuyStopLine";
bool testMode = true;  // set to true to draw without a real buy (will auto-disable if a real buy is found)

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("EA initialized. Drawing test line...");
   DrawOrLockLine(); // <-- draw immediately on start
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Handles drawing, updating, and locking the line                 |
//+------------------------------------------------------------------+
void DrawOrLockLine()
  {
   double basePrice = 0.0;
   bool positionFound = false;

   // 1. Check if there is an active buy position for this symbol
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.PositionType() == POSITION_TYPE_BUY)
           {
            basePrice = m_position.PriceOpen(); // Lock onto the actual entry price
            positionFound = true;
            break; // Found our buy order, exit loop
           }
        }
     }

   // 2. Determine price based on context
   if(positionFound)
     {
      // If a real position is open, override testMode and lock the line
      if(testMode)
        {
         testMode = false;
         Print("Live Buy Position detected! Switching out of Test Mode and locking line.");
        }
     }
   else if(testMode)
     {
      // Standard test mode tracking (market tracking)
      basePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // Fallback if market is closed
      if(basePrice <= 0)
         basePrice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
     }
   else
     {
      // Test mode is false, but no live position is open. 
      // Do nothing to avoid resetting the line back to Bid price.
      return; 
     }

   // 3. Calculate the line position
   double linePrice = basePrice * (1.0 - LineOffsetP / 100.0);

   // 4. Create or Update the line
   if(ObjectFind(0, LineName) < 0) // ObjectFind returns -1 if object doesn't exist
     {
      ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, linePrice);
      ObjectSetInteger(0, LineName, OBJPROP_COLOR, LineColor);
      ObjectSetInteger(0, LineName, OBJPROP_WIDTH, LineWidth);
      PrintFormat("Line created at %.5f (%.2f%% below %.5f)", linePrice, LineOffsetP, basePrice);
     }
     else
     {
      // Only update if it actually moved to prevent chart flickering
      if(ObjectGetDouble(0, LineName, OBJPROP_PRICE) != linePrice)
        {
         ObjectSetDouble(0, LineName, OBJPROP_PRICE, linePrice);
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Call the function on every tick to either track the market or stay locked
   DrawOrLockLine();
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