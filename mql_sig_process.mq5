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
   double price; // Added to store signal price for backtesting
};

Signal signals[];
int signalCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("Pablo initializing for backtesting");
   // Hardcode file locations in MQL5\Files directory
   string filePath = "w.txt";
   string signalsFilePath = "signals.csv";
   // Get the full path to the files
   string fullFilePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filePath;
   string fullSignalsFilePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + signalsFilePath;
   
   // Open file for writing (w.txt)
   int handle = FileOpen(filePath, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if (handle == INVALID_HANDLE) {
      Print("Failed to open file for writing: ", fullFilePath, " Error: ", GetLastError());
      return(INIT_FAILED);
   }

   // Write "hello" to the file
   FileWrite(handle, "hello");
   Print("Successfully wrote 'hello' to ", fullFilePath);
   FileClose(handle);

   // Open signals.csv for reading
   int signalsHandle = FileOpen(signalsFilePath, FILE_READ | FILE_TXT | FILE_ANSI);
   if (signalsHandle == INVALID_HANDLE) {
      Print("Failed to open signals file: ", fullSignalsFilePath, " Error: ", GetLastError());
      return(INIT_FAILED);
   }

   // Resize signals array dynamically
   signalCount = 0;
   while (!FileIsEnding(signalsHandle)) {
      string line = FileReadString(signalsHandle);
      if (line == "") continue; // Skip empty lines

      // Split the line into timestamp, signal, and price
      string parts[];
      if (StringSplit(line, ',', parts) >= 2) { // Allow for optional price field
         // Resize signals array
         ArrayResize(signals, signalCount + 1);
         
         // Parse timestamp and signal
         signals[signalCount].time = StringToTime(parts[0]);
         signals[signalCount].type = parts[1];
         StringTrimLeft(signals[signalCount].type);
         StringTrimRight(signals[signalCount].type);
         
         // Parse price if available, otherwise use 0 (will use market price later)
         signals[signalCount].price = (ArraySize(parts) > 2) ? StringToDouble(parts[2]) : 0.0;
         
         // Validate signal type
         if (signals[signalCount].type != "BUY" && signals[signalCount].type != "SELL") {
            Print("Invalid signal type in line: ", line);
            continue;
         }
         
         // Validate timestamp
         if (signals[signalCount].time == 0) {
            Print("Invalid timestamp in line: ", line);
            continue;
         }
         
         signalCount++;
         Print("Loaded signal: ", parts[0], ", ", signals[signalCount-1].type, 
               ", Price: ", (signals[signalCount-1].price > 0 ? DoubleToString(signals[signalCount-1].price, _Digits) : "Market"));
      } else {
         Print("Invalid CSV format in line: ", line);
      }
   }

   FileClose(signalsHandle);
   Print("Loaded ", signalCount, " signals from ", fullSignalsFilePath);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Clean up all objects created by the EA
   ObjectsDeleteAll(0, "Signal_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   static int currentIndex = 0;
   // Use the current bar's open time for backtesting
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if (currentIndex >= signalCount) return;

   // Check if the current bar's time has reached or passed the signal's time
   if (currentBarTime >= signals[currentIndex].time) {
      CTrade trade;
      double lotSize = 27; // Adjusted for backtesting; modify as needed
      ENUM_ORDER_TYPE orderType = (signals[currentIndex].type == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      // Use signal price if provided, otherwise use market price
      double price = signals[currentIndex].price > 0 ? signals[currentIndex].price : 
                     (orderType == ORDER_TYPE_BUY ? iOpen(_Symbol, PERIOD_CURRENT, 0) : iOpen(_Symbol, PERIOD_CURRENT, 0));

      // Open position (use market price for execution in backtesting)
      if (trade.PositionOpen(_Symbol, orderType, lotSize, price, 0, 0)) {
         Print("Opened ", signals[currentIndex].type, " at signal time ", 
               TimeToString(signals[currentIndex].time), 
               ", bar time ", TimeToString(currentBarTime), 
               ", price ", DoubleToString(price, _Digits));

         // Add a larger circle on the chart
         string objName = "Signal_" + IntegerToString(currentIndex) + "_" + TimeToString(signals[currentIndex].time, TIME_DATE|TIME_MINUTES);
         color clr = (orderType == ORDER_TYPE_BUY) ? clrGreen : clrRed;

         // Create an arrow (larger circle) object
         if (!ObjectCreate(0, objName, OBJ_ARROW, 0, signals[currentIndex].time, price)) {
            Print("Failed to create object for ", signals[currentIndex].type, ", Error: ", GetLastError());
         } else {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 5); // Increased width for larger circles
            ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159); // Circle symbol
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);
            ObjectSetDouble(0, objName, OBJPROP_SCALE, 2.0); // Scale factor to make the circle larger
         }
      } else {
         Print("Failed to open ", signals[currentIndex].type, 
               " at signal time ", TimeToString(signals[currentIndex].time), 
               ", bar time ", TimeToString(currentBarTime), 
               ", price ", DoubleToString(price, _Digits), 
               ", Error: ", trade.ResultRetcode());
      }

      currentIndex++;
   }
}
//+------------------------------------------------------------------+