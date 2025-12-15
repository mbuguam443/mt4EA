//+------------------------------------------------------------------+
//|                                                 testingHello.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int MAGIC = 123456;
input double Riskpercent=2;
input int RangeStartHour=3;
input int RangeStartMin=0;
input int RangeEndHour=6;
input int RangeEndMin=0;
input int TradingEndHour=18;
input int TradingEndMin=0;


datetime rangeTimeStart;
datetime rangeTimeEnd;
datetime tradingTimeEnd;


double rangeHigh;
double rangeLow;

bool isTrade;

int OnInit()
  {
   
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
    calcTimes();
    calcRange();
    
    double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
    
    if(TimeCurrent()>rangeTimeEnd && TimeCurrent() < tradingTimeEnd)
      {
      
       if(!isTrade)
         {
           if(rangeHigh>0 && rangeLow>0)
          {
           if(bid>rangeHigh)
            {
             //buy
             double lots=calcLots();
             Print("==============we buy ",lots," now=======================");
             int ticket=OrderSend(_Symbol,OP_BUY,lots,Ask,100,rangeLow,0,"Mt4 buy range breakout",MAGIC,0,clrBlue);
             Print("Ticket number: ",ticket);
             isTrade=true;
            }else if(bid<rangeLow)
            {
             //sell 
             double lots=calcLots();
             Print("==============we sell ",lots," now======================");
             int ticket=OrderSend(_Symbol,OP_SELL,lots,Bid,100,rangeHigh,0,"Mt4 sell  range breakout",MAGIC,0,clrRed);
             Print("Ticket number: ",ticket);
             isTrade=true;
               
            }
          }
         }
        
          
      }else if (TimeCurrent()>=tradingTimeEnd)
      {
         
         //Print("we close all positions now go home current time: ",TimeCurrent()," endtrade: ",tradingTimeEnd);
         
          CloseAllPositions(MAGIC);
      }
      
   
  }
//+------------------------------------------------------------------+

void calcTimes()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour=RangeStartHour;
   dt.min=RangeStartMin;
   dt.sec=0;
   
   if(rangeTimeStart!=StructToTime(dt))
     {
      isTrade=false;
      rangeHigh=0;
      rangeLow=0;
     }
   
   rangeTimeStart=StructToTime(dt);
   
   dt.hour=RangeEndHour;
   dt.min=RangeEndMin;
   rangeTimeEnd=StructToTime(dt);
   
   
   dt.hour=TradingEndHour;
   dt.min=TradingEndMin;
   tradingTimeEnd=StructToTime(dt);
   
   //Print("RangeTimeStart: ",rangeTimeStart," RangeTimeEnd: ",rangeTimeEnd," TradingTimeend: ",tradingTimeEnd);
}

void calcRange()
{
  double highs[];
  CopyHigh(_Symbol,PERIOD_CURRENT,rangeTimeStart,rangeTimeEnd,highs);
  
  double lows[];
  CopyLow(_Symbol,PERIOD_CURRENT,rangeTimeStart,rangeTimeEnd,lows);
  
  if(ArraySize(highs)<1 || ArraySize(lows)<1){ return;}
  
  int indexHighest=ArrayMaximum(highs);
  int indexLowest =ArrayMinimum(lows);
  
  rangeHigh=highs[indexHighest];
  rangeLow=lows[indexLowest];
  
  //Print("rangeHighest: ",rangeHigh," rangeLowest: ",rangeLow);
  
  DrawObject();


}

void DrawObject()
{
  string objName="Range "+TimeToString(rangeTimeStart,TIME_DATE);
  if(ObjectFind(0,objName)<0)
    {
      ObjectCreate(0,objName,OBJ_RECTANGLE,0,rangeTimeStart,rangeLow,rangeTimeEnd,rangeHigh);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clrPurple);
    }else{
     ObjectSetDouble(0,objName,OBJPROP_PRICE,0,rangeLow);
     ObjectSetDouble(0,objName,OBJPROP_PRICE,1,rangeHigh);
    }
 

   string vline = "VLINE_" + TimeToString(tradingTimeEnd, TIME_DATE);
   if(ObjectFind(0,vline)<0)
     {
         ObjectDelete(0, vline);
         ObjectCreate(0, vline, OBJ_VLINE, 0, tradingTimeEnd, 0);
         ObjectSetInteger(0, vline, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, vline, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, vline, OBJPROP_STYLE, STYLE_SOLID);
     }
  
}

double calcLots()
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
   double rangeSize=rangeHigh-rangeLow;
   
   double riskperLot=rangeSize/tickSize*tickValue;
   
   double RiskMoney=AccountInfoDouble(ACCOUNT_BALANCE)*0.01*Riskpercent;
   
   double lots=RiskMoney/riskperLot;
   
   
   int digits = (step == 0.1) ? 1 : 2;
   lots = NormalizeDouble(lots, digits);
  
   
   Print("Final lots = ", lots,
      " | min = ", MarketInfo(Symbol(), MODE_MINLOT),
      " | max = ", MarketInfo(Symbol(), MODE_MAXLOT),
      " | step = ", MarketInfo(Symbol(), MODE_LOTSTEP));

   return lots;
}


void CloseAllPositions(int magic)
{
   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderMagicNumber() != magic)
         continue;

      if(OrderSymbol() != Symbol())
         continue;

      bool closed = false;

      if(OrderType() == OP_BUY)
      {
         closed = OrderClose(
            OrderTicket(),
            OrderLots(),
            Bid,
            5,
            clrBlue
         );
      }
      else if(OrderType() == OP_SELL)
      {
         closed = OrderClose(
            OrderTicket(),
            OrderLots(),
            Ask,
            5,
            clrRed
         );
      }

      if(!closed)
      {
         Print("Close failed. Ticket=", OrderTicket(),
               " Error=", GetLastError());
      }
   }
}
