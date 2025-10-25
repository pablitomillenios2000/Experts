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
};

Signal signals[];
int signalCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("Pablo initializing");
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

      // Split the line into timestamp and signal
      string parts[];
      if (StringSplit(line, ',', parts) == 2) {
         // Resize signals array
         ArrayResize(signals, signalCount + 1);
         
         // Parse timestamp and signal
         signals[signalCount].time = StringToTime(parts[0]);
         signals[signalCount].type = parts[1];
         StringTrimLeft(signals[signalCount].type);
         StringTrimRight(signals[signalCount].type);
         
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
         Print("Loaded signal: ", parts[0], ", ", signals[signalCount-1].type);
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
   // Nothing to do
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   static int currentIndex = 0;
   datetime now = TimeCurrent();

   if (currentIndex >= signalCount) return;

   if (now >= signals[currentIndex].time) {
      CTrade trade;
      double lotSize = 0.01; // Small lot size for testing; adjust as needed
      ENUM_ORDER_TYPE orderType = (signals[currentIndex].type == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      // Capture the exact market timestamp at the moment of trade attempt
      datetime tradeTime = TimeCurrent();
      
      // Open position (assuming hedging mode; if netting, you may need to close previous)
      if (trade.PositionOpen(_Symbol, orderType, lotSize, 0, 0, 0)) {
         Print("Opened ", signals[currentIndex].type, " at signal time ", 
               TimeToString(signals[currentIndex].time), 
               ", market time ", TimeToString(tradeTime));
      } else {
         Print("Failed to open ", signals[currentIndex].type, 
               " at signal time ", TimeToString(signals[currentIndex].time), 
               ", market time ", TimeToString(tradeTime), 
               ", Error: ", trade.ResultRetcode());
      }

      currentIndex++;
   }
}
//+------------------------------------------------------------------+