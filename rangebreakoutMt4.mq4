//+------------------------------------------------------------------+
//|                                                 testingHello.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict



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
             Print("==============we buy now=======================");
             isTrade=true;
            }else if(bid<rangeLow)
            {
             //sell 
             Print("==============we sell now======================");
             isTrade=true;  
            }
          }
         }
        
          
      }else if (TimeCurrent()>=tradingTimeEnd)
      {
         
         Print("we close all positions now go home");
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