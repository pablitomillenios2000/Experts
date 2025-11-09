//+------------------------------------------------------------------+
//|                                                  DrawStopLine.mq5 |
//|                                       Created by ChatGPT (GPT-5) |
//+------------------------------------------------------------------+
#property strict

//--- input parameters
input color   LineColor   = clrPurple;   // Line color
input int     LineWidth   = 3;           // Line width
input double  LineOffsetP = 0.5;         // Line offset in percent (below buy price)

//--- line name
string LineName = "BuyStopLine";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("EA initialized: Draws line 0.5% below buy price, deletes on sell.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static bool lineDrawn = false;

   //--- Check for open positions
   int total = PositionsTotal();

   //--- If there is no position, delete line if exists
   if(total == 0)
     {
      if(ObjectFind(0, LineName) == 0)
        {
         ObjectDelete(0, LineName);
         Print("No position found — line deleted.");
        }
      lineDrawn = false;
      return;
     }

   //--- Only handle unhedged long positions
   for(int i = 0; i < total; i++)
     {
      string symbol = PositionGetSymbol(i);
      if(PositionSelect(symbol))
        {
         long   type  = PositionGetInteger(POSITION_TYPE);
         double price = PositionGetDouble(POSITION_PRICE_OPEN);

         //--- Only process BUY positions
         if(type == POSITION_TYPE_BUY)
           {
            //--- Calculate line price (0.5% below open price)
            double linePrice = price * (1.0 - LineOffsetP / 100.0);

            //--- Create or update the line
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
            lineDrawn = true;
            return;
           }
        }
     }

   //--- If position is not BUY, delete line
   if(lineDrawn)
     {
      ObjectDelete(0, LineName);
      lineDrawn = false;
      Print("Buy position closed or not found — line removed.");
     }
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0, LineName);
   Print("EA deinitialized — line removed.");
  }
//+------------------------------------------------------------------+
