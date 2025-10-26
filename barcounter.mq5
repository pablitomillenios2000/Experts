//+------------------------------------------------------------------+
//|                                     HelloWorldLastTenBars.mq5     |
//|                        Copyright 2025, xAI                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI"
#property link      ""
#property version   "1.00"
#property strict
#property description "EA that prints 'he' above the last 10 bars."

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
   PlaceHeLabels();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteAllLabels();
   Print("EA Deinitialized, reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update labels on new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      PlaceHeLabels();
      Print("New bar detected: ", TimeToString(currentBarTime));
   }
}

//+------------------------------------------------------------------+
//| Place "he" above the last 10 bars                                |
//+------------------------------------------------------------------+
void PlaceHeLabels()
{
   // Get last 10 bars' high and time
   double highArray[];
   datetime timeArray[];
   ArraySetAsSeries(highArray, true);
   ArraySetAsSeries(timeArray, true);
   int barsToCopy = 10;
   if(CopyHigh(_Symbol, _Period, 0, barsToCopy, highArray) < barsToCopy || 
      CopyTime(_Symbol, _Period, 0, barsToCopy, timeArray) < barsToCopy)
   {
      Print("Error: Failed to copy data for last 10 bars");
      return;
   }
   
   // Delete previous labels
   DeleteAllLabels();
   
   // Place "he" above each of the last 10 bars
   for(int i = 0; i < barsToCopy; i++)
   {
      string name = "HeLabel_" + IntegerToString(i);
      double price = highArray[i] + LabelOffset * _Point;
      datetime time = timeArray[i];
      
      if(ObjectCreate(ChartID(), name, OBJ_TEXT, 0, time, price))
      {
         ObjectSetString(ChartID(), name, OBJPROP_TEXT, "he");
         ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, LabelColor);
         ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, ANCHOR_LOWER);
         Print("Placed 'he' above bar ", i, " at ", TimeToString(time));
      }
      else
      {
         Print("Failed to create label for bar ", i, ", Error: ", GetLastError());
      }
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete all labels                                                |
//+------------------------------------------------------------------+
void DeleteAllLabels()
{
   for(int obj = ObjectsTotal(ChartID(), 0, OBJ_TEXT) - 1; obj >= 0; obj--)
   {
      string name = ObjectName(ChartID(), obj);
      if(StringFind(name, "HeLabelਮLabel_") == 0)
      {
         ObjectDelete(ChartID(), name);
      }
   }
}