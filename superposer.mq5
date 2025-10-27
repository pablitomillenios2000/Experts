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
input string FontName = "Arial";             // Font name
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
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      PlaceLabels();
   }
}

//+------------------------------------------------------------------+
//| Load labels from CSV                                             |
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
//| Get price at pixel offset up from base                           |
//+------------------------------------------------------------------+
double GetPriceAtPixelOffset(datetime time_val, double base_price, int pixel_offset)
{
   int x, y;
   if(!ChartTimePriceToXY(ChartID(), 0, time_val, base_price, x, y))
   {
      Print("Failed to convert time/price to XY");
      return base_price;
   }

   int target_y = y - pixel_offset;  // Positive offset up (smaller y)

   datetime dummy_time;
   double target_price;
   int dummy_window;
   if(!ChartXYToTimePrice(ChartID(), x, target_y, dummy_window, dummy_time, target_price))
   {
      Print("Failed to convert XY to time/price");
      return base_price;
   }

   return target_price;
}

//+------------------------------------------------------------------+
//| Place labels above candles                                       |
//+------------------------------------------------------------------+
void PlaceLabels()
{
   DeleteAllLabels();

   // Get text height
   uint dummy_width, text_height;
   TextSetFont(FontName, FontSize, 0);
   TextGetSize("X", dummy_width, text_height);

   for(int i = 0; i < ArraySize(labels); i++)
   {
      datetime time_val = labels[i].time;
      int bar_index = iBarShift(_Symbol, Period(), time_val, false);
      if(bar_index < 0)
      {
         Print("Bar not found for time: ", TimeToString(time_val));
         continue;
      }

      double high_price = iHigh(_Symbol, Period(), bar_index);

      // Get delta price per pixel (for 1 px up)
      double delta_price_per_px = GetPriceAtPixelOffset(time_val, high_price, 1) - high_price;

      if(MathAbs(delta_price_per_px) < _Point / 10.0)
      {
         Print("Invalid price scale for time: ", TimeToString(time_val));
         continue;
      }

      for(int j = 0; j < ArraySize(labels[i].symbols); j++)
      {
         string name = "Label_" + IntegerToString(i) + "_" + IntegerToString(j);
         string symbol = labels[i].symbols[j];

         // Calculate total pixel offset up for this label's anchor (bottom)
         int total_pixel_offset = InitialPixelOffset + j * ((int)text_height + SymbolSpacing);

         double anchor_price = high_price + total_pixel_offset * delta_price_per_px;

         if(ObjectCreate(ChartID(), name, OBJ_TEXT, 0, time_val, anchor_price))
         {
            ObjectSetString(ChartID(), name, OBJPROP_TEXT, symbol);
            ObjectSetString(ChartID(), name, OBJPROP_FONT, FontName);
            ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, LabelColor);
            ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, ANCHOR_LOWER);
            Print("Placed '", symbol, "' at ", TimeToString(time_val), " anchor price ", DoubleToString(anchor_price, _Digits));
         }
         else
         {
            Print("Failed to create label '", symbol, "' for ", TimeToString(time_val), " Error: ", GetLastError());
         }
      }
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete all labels                                                |
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