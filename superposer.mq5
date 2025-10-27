//+------------------------------------------------------------------+
//|                                   MarkLocalMaxima.mq5            |
//|                        Copyright 2025, xAI                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI"
#property version   "1.00"
#property strict
#property description "Places labels from CSV above bars, stacked vertically with 10px separation."

// Input parameters
input string FileName = "local_maxima.csv";  // CSV file in MQL5/Files/
input color  LabelColor = clrYellow;         // Label color
input int    FontSize = 12;                  // Font size
input int    InitialPixelOffset = 10;        // Initial offset in pixels above the bar
input int    SymbolSpacing = 10;             // Vertical spacing between symbols in pixels

// Structure to store label data
struct CandleLabel
{
   datetime time;
   string   symbols[];
};

// Array to hold label data
CandleLabel labels[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA Initialized on ", _Symbol, " Timeframe: ", Period());
   if(!LoadCandleLabels(FileName))
   {
      Print("Error loading labels from file: ", FileName);
      return(INIT_FAILED);
   }
   
   PlaceLabels();
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
   // Do nothing — labels are static
}

//+------------------------------------------------------------------+
//| Load labels from CSV                                            |
//+------------------------------------------------------------------+
bool LoadCandleLabels(string filename)
{
   ResetLastError();
   int file = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(file == INVALID_HANDLE)
   {
      Print("Failed to open file: ", filename, " Error: ", GetLastError());
      return false;
   }

   // Skip header
   FileReadString(file);

   // Read each line
   while(!FileIsEnding(file))
   {
      string date_str = FileReadString(file);
      if(date_str == "") break;

      datetime dt = StringToTime(date_str);
      if(dt <= 0) continue;

      // Read all remaining fields as symbols
      string symbols[];
      int symbol_count = 0;
      while(!FileIsLineEnding(file) && !FileIsEnding(file))
      {
         string symbol = FileReadString(file);
         if(symbol != "")
         {
            ArrayResize(symbols, symbol_count + 1);
            symbols[symbol_count] = symbol;
            symbol_count++;
         }
      }

      if(symbol_count > 0)
      {
         CandleLabel label;
         label.time = dt;
         ArrayResize(label.symbols, symbol_count);
         for(int i = 0; i < symbol_count; i++)
            label.symbols[i] = symbols[i];
         ArrayResize(labels, ArraySize(labels) + 1);
         labels[ArraySize(labels) - 1] = label;
      }
   }

   FileClose(file);
   Print("Loaded ", ArraySize(labels), " label sets from ", filename);
   return ArraySize(labels) > 0;
}

//+------------------------------------------------------------------+
//| Place labels above candles                                       |
//+------------------------------------------------------------------+
void PlaceLabels()
{
   DeleteAllLabels();

   for(int i = 0; i < ArraySize(labels); i++)
   {
      datetime time = labels[i].time;
      int bar_index = iBarShift(_Symbol, Period(), time, false);
      if(bar_index < 0)
      {
         Print("Bar not found for time: ", TimeToString(time));
         continue;
      }

      double high_price = iHigh(_Symbol, Period(), bar_index);
      for(int j = 0; j < ArraySize(labels[i].symbols); j++)
      {
         string name = "Label_" + IntegerToString(i) + "_" + IntegerToString(j);
         string symbol = labels[i].symbols[j];
         int y_offset = InitialPixelOffset + (j * SymbolSpacing);

         if(ObjectCreate(ChartID(), name, OBJ_TEXT, 0, time, high_price))
         {
            ObjectSetString(ChartID(), name, OBJPROP_TEXT, symbol);
            ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, LabelColor);
            ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, ANCHOR_LOWER);
            ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, y_offset);
            Print("Placed '", symbol, "' at ", TimeToString(time), " offset ", y_offset, "px");
         }
         else
         {
            Print("Failed to create label '", symbol, "' for ", TimeToString(time), " Error: ", GetLastError());
         }
      }
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete all labels                                               |
//+------------------------------------------------------------------+
void DeleteAllLabels()
{
   for(int i = ObjectsTotal(ChartID(), 0, OBJ_TEXT) - 1; i >= 0; i--)
   {
      string name = ObjectName(ChartID(), i);
      if(StringFind(name, "Label_") == 0)
         ObjectDelete(ChartID(), name);
   }
}