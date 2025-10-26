//+------------------------------------------------------------------+
//|                                     HelloWorldLastBar.mq5         |
//|                        Copyright 2025, xAI                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI"
#property link      ""
#property version   "1.00"
#property strict
#property description "EA that prints 'Hello World' above the last bar."

// Input parameters
input double LabelOffset = 1000.0; // Offset above high in points
input color LabelColor = clrRed;   // Label color
input int FontSize = 10;           // Font size

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA Initialized on ", _Symbol, " Timeframe: ", Period());
   PlaceHelloWorldLabel();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(ChartID(), "HelloWorldLabel");
   Print("EA Deinitialized, reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update label on new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      PlaceHelloWorldLabel();
      Print("New bar detected: ", TimeToString(currentBarTime));
   }
}

//+------------------------------------------------------------------+
//| Place "Hello World" above the last bar                           |
//+------------------------------------------------------------------+
void PlaceHelloWorldLabel()
{
   // Get last bar's high and time
   double highArray[];
   datetime timeArray[];
   ArraySetAsSeries(highArray, true);
   ArraySetAsSeries(timeArray, true);
   if(CopyHigh(_Symbol, _Period, 0, 1, highArray) < 1 || CopyTime(_Symbol, _Period, 0, 1, timeArray) < 1)
   {
      Print("Error: Failed to copy data for last bar");
      return;
   }
   
   // Delete previous label
   ObjectDelete(ChartID(), "HelloWorldLabel");
   
   // Place new label
   double price = highArray[0] + LabelOffset * _Point;
   datetime time = timeArray[0];
   
   if(ObjectCreate(ChartID(), "HelloWorldLabel", OBJ_TEXT, 0, time, price))
   {
      ObjectSetString(ChartID(), "HelloWorldLabel", OBJPROP_TEXT, "Hello World");
      ObjectSetInteger(ChartID(), "HelloWorldLabel", OBJPROP_COLOR, LabelColor);
      ObjectSetInteger(ChartID(), "HelloWorldLabel", OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(ChartID(), "HelloWorldLabel", OBJPROP_ANCHOR, ANCHOR_LOWER);
      Print("Placed 'Hello World' above bar at ", TimeToString(time));
   }
   else
   {
      Print("Failed to create label, Error: ", GetLastError());
   }
   
   ChartRedraw();
}