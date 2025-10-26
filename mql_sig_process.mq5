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
   double price; // Store signal price for backtesting
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
//| Check if there is an open buy position                           |
//+------------------------------------------------------------------+
bool IsBuyPositionOpen() {
   if (PositionsTotal() > 0) {
      if (PositionSelect(_Symbol)) {
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            return true;
         }
      }
   }
   return false;
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
      double lotSize = 30; // Adjusted for backtesting; modify as needed
      string signalType = signals[currentIndex].type;
      double signalPrice = signals[currentIndex].price > 0 ? signals[currentIndex].price : iOpen(_Symbol, PERIOD_CURRENT, 0);

      if (signalType == "BUY") {
         ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;

         // Open buy position without SL initially
         if (trade.PositionOpen(_Symbol, orderType, lotSize, signalPrice, 0, 0)) {  // Use signalPrice for order
            Print("Opened BUY at signal time ", TimeToString(signals[currentIndex].time), 
                  ", bar time ", TimeToString(currentBarTime), 
                  ", requested price ", DoubleToString(signalPrice, _Digits));

            // Get the position ticket
            ulong positionTicket = 0;
            if (PositionSelect(_Symbol)) {
               positionTicket = PositionGetInteger(POSITION_TICKET);
            }
            
            if (positionTicket > 0) {
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double sl = NormalizeDouble(entryPrice * (1 - 0.006), _Digits); // Set SL 0.6% below entry

               // Modify to add SL
               if (trade.PositionModify(positionTicket, sl, 0)) {
                  Print("Added SL to BUY at ", DoubleToString(sl, _Digits));
               } else {
                  Print("Failed to add SL to BUY, Error: ", trade.ResultRetcode());
               }

               // Add a larger circle on the chart using entry price
               string objName = "Signal_" + IntegerToString(currentIndex) + "_" + TimeToString(signals[currentIndex].time, TIME_DATE|TIME_MINUTES);
               color clr = clrGreen;

               if (!ObjectCreate(0, objName, OBJ_ARROW, 0, signals[currentIndex].time, entryPrice)) {
                  Print("Failed to create object for BUY, Error: ", GetLastError());
               } else {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
                  ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, objName, OBJPROP_WIDTH, 5);
                  ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159);
                  ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                  ObjectSetDouble(0, objName, OBJPROP_SCALE, 2.0);
               }
            } else {
               Print("Failed to select position for BUY at signal time ", TimeToString(signals[currentIndex].time));
            }
         } else {
            Print("Failed to open BUY at signal time ", TimeToString(signals[currentIndex].time), 
                  ", bar time ", TimeToString(currentBarTime), 
                  ", requested price ", DoubleToString(signalPrice, _Digits), 
                  ", Error: ", trade.ResultRetcode());
         }
         currentIndex++;
      } else if (signalType == "SELL") {
         // Check if there is an open buy position
         if (IsBuyPositionOpen()) {
            ENUM_ORDER_TYPE orderType = ORDER_TYPE_SELL;

            // Open sell to close the buy
            if (trade.PositionOpen(_Symbol, orderType, lotSize, signalPrice, 0, 0)) {  // Use signalPrice for order
               Print("Opened SELL (close) at signal time ", TimeToString(signals[currentIndex].time), 
                     ", bar time ", TimeToString(currentBarTime), 
                     ", requested price ", DoubleToString(signalPrice, _Digits));

               // Add a larger circle on the chart (using signal price or market)
               double exitPrice = signalPrice; // Fallback to signal price
               if (PositionSelect(_Symbol)) {
                  exitPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
               }

               string objName = "Signal_" + IntegerToString(currentIndex) + "_" + TimeToString(signals[currentIndex].time, TIME_DATE|TIME_MINUTES);
               color clr = clrRed;

               if (!ObjectCreate(0, objName, OBJ_ARROW, 0, signals[currentIndex].time, exitPrice)) {
                  Print("Failed to create object for SELL, Error: ", GetLastError());
               } else {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
                  ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, objName, OBJPROP_WIDTH, 5);
                  ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159);
                  ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                  ObjectSetDouble(0, objName, OBJPROP_SCALE, 2.0);
               }
            } else {
               Print("Failed to open SELL at signal time ", TimeToString(signals[currentIndex].time), 
                     ", bar time ", TimeToString(currentBarTime), 
                     ", requested price ", DoubleToString(signalPrice, _Digits), 
                     ", Error: ", trade.ResultRetcode());
            }
         } else {
            Print("Skipping SELL at signal time ", TimeToString(signals[currentIndex].time), 
                  " because no open BUY position (SL likely triggered)");
         }
         currentIndex++;
      }
   }
}
//+------------------------------------------------------------------+