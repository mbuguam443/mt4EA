//+------------------------------------------------------------------+
//|                                               creatingOrders.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    double lots = MarketInfo(Symbol(), MODE_MINLOT);
      double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
      
      double price = Ask + (stopLevel * 2);
      double sl    = price - (stopLevel * 3);
      double tp    = price + (stopLevel * 6);
      
      int ticket = OrderSend(
         Symbol(),
         OP_BUYSTOP,
         lots,
         NormalizeDouble(price, Digits),
         3,
         NormalizeDouble(sl, Digits),
         NormalizeDouble(tp, Digits),
         "TEST BUY STOP",
         0,
         0,
         clrBlue
      );
      
      Print("Pending Ticket = ", ticket, " Error = ", GetLastError());
   

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
bool placed = false;

void OnTick()
{
   if(placed) return;

   double lots = MarketInfo(Symbol(), MODE_MINLOT);

   // Pip calculation (4 & 5 digit safe)
   double pip = (Digits == 3 || Digits == 5) ? 10 * Point : Point;

   // === NARROW BUT SAFE DISTANCES ===
   double entryDistance = 90 * pip;   // 20 pips away
   double slDistance    = 40 * pip;   // 40 pips SL
   double tpDistance    = 80 * pip;   // 80 pips TP

   double price = Bid - entryDistance; // SELL STOP below price
   double sl    = price + slDistance;  // SL above
   double tp    = price - tpDistance;  // TP below

   int ticket = OrderSend(
      Symbol(),
      OP_SELLSTOP,
      lots,
      NormalizeDouble(price, Digits),
      3,
      NormalizeDouble(sl, Digits),
      NormalizeDouble(tp, Digits),
      "NORMAL SELL STOP",
      999,
      0,
      clrRed
   );

   Print("Sell Stop Ticket = ", ticket, " Error = ", GetLastError());

   if(ticket > 0)
      placed = true;
}
//+------------------------------------------------------------------+
