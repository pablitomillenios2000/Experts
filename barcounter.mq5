//+------------------------------------------------------------------+
//|                                   MarkLocalMaxima.mq5            |
//|                        Copyright 2025, xAI                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, xAI"
#property version   "1.00"
#property strict
#property description "Places a yellow 'X' label 5 pixels above bars matching datetimes in local_maxima.csv."

// Input parameters
input string FileName = "local_maxima.csv";  // CSV file in MQL5/Files/
input color  LabelColor = clrYellow;         // Label color
input int    FontSize = 12;                  // Font size
input int    PixelOffset = 5;                // Offset in pixels above the bar

// Structure to store local maxima data
struct LocalMax
{
   datetime time;
   double   price;
};

// Array to hold maxima
LocalMax maxima[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA Initialized on ", _Symbol, " Timeframe: ", Period());
   if(!LoadLocalMaxima(FileName))
   {
      Print("Error loading local maxima from file: ", FileName);
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
//| Load local maxima from CSV                                       |
//+------------------------------------------------------------------+
bool LoadLocalMaxima(string filename)
{
   ResetLastError();
   int file = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(file == INVALID_HANDLE)
   {
      Print("Failed to open file: ", filename, " Error: ", GetLastError());
      return false;
   }

   // Skip header
   string header = FileReadString(file);
   FileReadString(file);

   // Read each line
   while(!FileIsEnding(file))
   {
      string date_str = FileReadString(file);
      string price_str = FileReadString(file);
      if(date_str == "" || price_str == "") break;

      datetime dt = StringToTime(date_str);
      double price = StringToDouble(price_str);

      if(dt > 0 && price > 0)
      {
         LocalMax m;
         m.time = dt;
         m.price = price;
         ArrayResize(maxima, ArraySize(maxima) + 1);
         maxima[ArraySize(maxima) - 1] = m;
      }
   }

   FileClose(file);
   Print("Loaded ", ArraySize(maxima), " local maxima from ", filename);
   return ArraySize(maxima) > 0;
}

//+------------------------------------------------------------------+
//| Place 'X' labels for local maxima                                |
//+------------------------------------------------------------------+
void PlaceLabels()
{
   DeleteAllLabels();

   for(int i = 0; i < ArraySize(maxima); i++)
   {
      string name = "MaxLabel_" + IntegerToString(i);
      double price = maxima[i].price;
      datetime time = maxima[i].time;

      if(ObjectCreate(ChartID(), name, OBJ_TEXT, 0, time, price))
      {
         ObjectSetString(ChartID(), name, OBJPROP_TEXT, "X");
         ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, LabelColor);
         ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, ANCHOR_LOWER);
         ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, PixelOffset);
         Print("Placed 'X' at ", TimeToString(time), " price ", DoubleToString(price, _Digits));
      }
      else
      {
         Print("Failed to create label for ", TimeToString(time), " Error: ", GetLastError());
      }
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete all 'X' labels                                            |
//+------------------------------------------------------------------+
void DeleteAllLabels()
{
   for(int i = ObjectsTotal(ChartID(), 0, OBJ_TEXT) - 1; i >= 0; i--)
   {
      string name = ObjectName(ChartID(), i);
      if(StringFind(name, "MaxLabel_") == 0)
         ObjectDelete(ChartID(), name);
   }
}
