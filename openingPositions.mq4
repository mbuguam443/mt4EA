//+------------------------------------------------------------------+
//|                                             openingPositions.mq4 |
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
  
  
    //int ticket=OrderSend(_Symbol,OP_BUY,0.01,Bid,1000,0,0,"yes man",17265,0,clrBlue);
   // Print("Ticket:====",ticket);
    
    int ticket=OrderSend(_Symbol,OP_SELL,0.01,Ask,1000,0,0,"yes man",17265,0,clrRed);
    Print("Ticket:====",ticket);
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
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
