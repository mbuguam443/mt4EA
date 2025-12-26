#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input long Magic=83764;
input double Lots=0.01;
input int maFastPeriod=20;
input int maSlowPeriod=50;
input int TpPercent=800; //TP Points
input int SlPercent=200; //Sl Points

int barsTotals;

int OnInit()
  {
   barsTotals=iBars(_Symbol,PERIOD_CURRENT);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     int bars=iBars(_Symbol,PERIOD_CURRENT);
     if(barsTotals!=bars)
       {
        barsTotals=bars;
        double maFast1=iMA(_Symbol,PERIOD_CURRENT,maFastPeriod,0,MODE_EMA,PRICE_CLOSE,1);
        double maFast2=iMA(_Symbol,PERIOD_CURRENT,maFastPeriod,0,MODE_EMA,PRICE_CLOSE,2);
        
        
        double maSlow1=iMA(_Symbol,PERIOD_CURRENT,maSlowPeriod,0,MODE_EMA,PRICE_CLOSE,1);
        double maSlow2=iMA(_Symbol,PERIOD_CURRENT,maSlowPeriod,0,MODE_EMA,PRICE_CLOSE,2);
        //Print("fastma1: ",maFast1," fastma2: ",maFast2," slowma1: ",maSlow1," slowma2: ",maSlow2);
        
        if(maFast1>maSlow1 && maFast2 <maSlow2)
          {
           Print("Buy Now");
           double entry=Ask;
           entry=NormalizeDouble(entry,_Digits);
           
           double sl=entry-entry*SlPercent;
           sl=NormalizeDouble(sl,_Digits);
           
           double tp=entry+entry*TpPercent;
           tp=NormalizeDouble(tp,_Digits);
           int ticketno=OrderSend(_Symbol,OP_BUY,Lots,entry,10000,sl,tp,"MA crossover BUY",Magic,0,clrBlue);
          }
         if(maFast1<maSlow1 && maFast2 >maSlow2)
          {
           Print("Sell Now");
           double entry=Bid;
           
           entry=NormalizeDouble(entry,_Digits);
           double sl=entry+entry*SlPercent;
           sl=NormalizeDouble(sl,_Digits);
           
           double tp=entry-entry*TpPercent;
           tp=NormalizeDouble(tp,_Digits);
           int ticketno=OrderSend(_Symbol,OP_SELL,Lots,entry,10000,sl,tp,"MA crossover SELL",Magic,0,clrRed);
          }  
       }
  
     
   
  }
//+------------------------------------------------------------------+
