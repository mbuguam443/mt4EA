//+------------------------------------------------------------------+
//|                                                 testingHello.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string url="https://fxaccountmanager.greatjourns.com/api.php";
enum BREAKOUT_MODE
  {
    ONE_SIDED=1,
    TWO_SIDED=2
  };
input BREAKOUT_MODE TriggerMode=ONE_SIDED;
input int MAGIC = 123456;
input double Riskpercent=2;
input bool TrailingStop=false;
input double rangePercent=0; // Range sl Percent (0=off)
input int RangeSizeFilter=1000; //RangeSizeFilter (0=off) 
input int RangeStartHour=3;
input int RangeStartMin=0;
input int RangeEndHour=6;
input int RangeEndMin=0;
input int TradingEndHour=18;
input int TradingEndMin=0;


datetime rangeTimeStart;
datetime rangeTimeEnd;
datetime tradingTimeEnd;
static bool handled = false;

double rangeHigh;
double rangeLow;

bool isTrade;

int OnInit()
  {
   EventSetTimer(5);
   return(INIT_SUCCEEDED);
  }
  void OnTimer()
   {
       InternetAuth();
       
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    calcTimes();
    calcRange();
    Comment("Daily Profit:============= ",CalculateDailyProfitTotal());
    if(!handled && IsBreakoutTriggered())
      {
         if(TriggerMode==ONE_SIDED)
           {
             DeleteOtherPending();
             handled = true; // prevent repeated execution
           }else if(TriggerMode==TWO_SIDED)
           {
             handled=true;     
           }
         
      }
    
    double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
    
    if(TimeCurrent()>rangeTimeEnd && TimeCurrent() < tradingTimeEnd)
      {
      
       if(!isTrade)
         {
           if(rangeHigh>0 && rangeLow>0 &&(RangeSizeFilter==0?true:(rangeHigh-rangeLow) <RangeSizeFilter))
          {
            Print("!!!!!!!!!!!!!!!!!!! rangeHigh: ",rangeHigh," rangeLow: ",rangeLow," range diff: ",rangeHigh-rangeLow," rangeFilter: ",RangeSizeFilter);
           //if(bid>rangeHigh)
            {
             //buy
             double lots=calcLots();
             Print("==============we buy ",lots," now=======================");
             // Pip calculation (4 & 5 digit safe)
               double pip = (Digits == 3 || Digits == 5) ? 10 * Point : Point;
            
               double buffer = 2 * pip;   // avoid spread / stop level issues
            
               /* ================= BUY STOP ================= */
               double buyPrice = rangeHigh + buffer;
               
               
               
               double buySL    = rangePercent==0? rangeLow :buyPrice-rangePercent*0.01*(rangeHigh-rangeLow);                 // RANGE LOW SL
               
            
               int buyTicket = OrderSend(
                  Symbol(),
                  OP_BUYSTOP,
                  lots,
                  NormalizeDouble(buyPrice, Digits),
                  3,
                  NormalizeDouble(buySL, Digits),
                  0,
                  "Range Breakout BUY",
                  MAGIC,
                  tradingTimeEnd,
                  clrBlue
               );
            
               Print("BUY STOP Ticket=", buyTicket, " Error=", GetLastError());
             isTrade=true;
             
            }
            //else if(bid<rangeLow)
            {
             //sell 
             double lots=calcLots();
             Print("==============we sell ",lots," now======================");
             // Pip calculation (4 & 5 digit safe)
            double pip = (Digits == 3 || Digits == 5) ? 10 * Point : Point;
            double buffer = 2 * pip;   // avoid spread / stop level issues
            double sellPrice = rangeLow - buffer;
            
            double sellSL    = rangePercent==0? rangeHigh :sellPrice+rangePercent*0.01*(rangeHigh-rangeLow);;
            
           
           
         
            int sellTicket = OrderSend(
               Symbol(),
               OP_SELLSTOP,
               lots,
               NormalizeDouble(sellPrice, Digits),
               3,
               NormalizeDouble(sellSL, Digits),
               0,
               "Range Breakout SELL",
               MAGIC,
               tradingTimeEnd,
               clrRed
            );
         
            Print("SELL STOP Ticket=", sellTicket, " Error=", GetLastError());
             isTrade=true;
               
            }
          }
         }
        
          
      }else if (TimeCurrent()>=tradingTimeEnd)
      {
         
         //Print("we close all positions now go home current time: ",TimeCurrent()," endtrade: ",tradingTimeEnd);
         
          CloseAllPositions(MAGIC);
      }
     if(TrailingStop)
       {
        trailingStopLoss();
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
      handled = false;
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
   double rangeSize=rangePercent==0?rangeHigh-rangeLow:rangePercent*0.01*(rangeHigh-rangeLow);
   
   double riskperLot=rangeSize/tickSize*tickValue;
   double RiskMoney=AccountInfoDouble(ACCOUNT_BALANCE)*0.01*Riskpercent;
   Print("Riskmoney: ",RiskMoney," riskperlot: ",riskperLot);
   
   
   
   double lots=RiskMoney/riskperLot;
   
   
   int digits = (step == 0.1) ? 1 : 2;
   lots = NormalizeDouble(lots, digits);
  
   
   Print("Final lots = ", lots,
      " | min = ", MarketInfo(Symbol(), MODE_MINLOT),
      " | max = ", MarketInfo(Symbol(), MODE_MAXLOT),
      " | step = ", MarketInfo(Symbol(), MODE_LOTSTEP));
      
   double minLots=MarketInfo(Symbol(), MODE_MINLOT);
   double maxLots=MarketInfo(Symbol(), MODE_MAXLOT);
     if(lots<minLots)
       {
        lots=minLots;
       }else if(lots>maxLots)
       {
        lots=maxLots;        
       }    

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
bool IsBreakoutTriggered()
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MAGIC){ 
             if(OrderType() == OP_BUY)
               {
                  Print("*************************A OP_BUY Position has been triggered");
                  
                  return true; // pending has triggered
                  
               }
               if(OrderType() == OP_SELL)
               {
                  Print("*************************A OP_SELL Position has been triggered");
                  
                  return true; // pending has triggered
                  
               }
         }
      }
   }
   return false;
}

void DeleteOtherPending()
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MAGIC &&
           (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP))
         {
            int results=OrderDelete(OrderTicket());
            Print("#################Order deleted");
         }
      }
   }
}

double CalculateDailyProfitTotal()
{
   double profit = 0.0;

   // Start of today (broker time)
   datetime todayStart = StrToTime(TimeToString(TimeCurrent(), TIME_DATE));

   /* ================= CLOSED TRADES (TODAY) ================= */
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(OrderCloseTime() >= todayStart)
         {
            profit += OrderProfit()
                    + OrderCommission()
                    + OrderSwap();
         }
      }
   }

   /* ================= OPEN TRADES (FLOATING) ================= */
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         profit += OrderProfit()
                 + OrderCommission()
                 + OrderSwap();
      }
   }

   return profit;
}


void trailingStopLoss()
{
    for(int i=OrdersTotal()-1;i>=0;i--)
      {
       if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
         if(OrderMagicNumber()==MAGIC)
           {
             if(OrderType()==OP_BUY)
               {
                if(Bid >OrderOpenPrice()+(rangeHigh-rangeLow))
                  {
                  
                   double sl=Bid-(rangeHigh-rangeLow);
                   sl=NormalizeDouble(sl,_Digits);
                   if(sl>OrderStopLoss()|| OrderStopLoss()==0)
                     {
                      if(OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),OrderExpiration()))
                      {
                       Print("@@@@@@@@@@@@@@@@@@@@@@Buy Order Modified Successfuly");
                      }
                     }
                  }
               }else if(OrderType()==OP_SELL)
               {
                  if(Ask < OrderOpenPrice()-(rangeHigh-rangeLow))
                    {
                     
                     double sl=Ask+(rangeHigh-rangeLow);
                     sl=NormalizeDouble(sl,_Digits);
                     if(sl<OrderStopLoss() || OrderStopLoss()==0)
                       {
                         if(OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),OrderExpiration()))
                           {
                            Print("@@@@@@@@@@@@@@@@@@@@@@@@Sell Order Modified Succeffuly");
                           }
                       }
                    }
               }
            }   
         }
      }
}

int InternetAuth()
{
   if(!MQLInfoInteger(MQL_TESTER) )
      {
          char post[];
          int accountNumber=9876; //AccountInfoInteger(ACCOUNT_LOGIN);
          
          string postText="{account_no="+IntegerToString(accountNumber)+"}";
          //string postText = "{\"account_no\": 9876}";
          StringToCharArray(postText, post, 0, StringLen(postText));  // Important: avoid null terminator
          //StringToCharArray(postText,post,0,WHOLE_ARRAY,CP_UTF8);
          char result[];
          string resultHeaders;
          
          int response= WebRequest("POST",url,NULL,1000,post,result,resultHeaders);
          Print("Server Response: ",response);
          Print("Results: ",CharArrayToString(result));
       
         
        
         
           
       if(response==200)
         {
            Print("Response 200: ",response);
            Print("Results 200: ",CharArrayToString(result));
            
            
            
         //{"accountno":1234,"symbol":"GPUSD.m","magicno":28374,"profit":30}   
         string json = CharArrayToString(result);//"{\"success\":true,\"lotsize\":0.02,\"tp\":600,\"sl\":200}";
         string accountnotxt="accountno";
         long  accountno = StringToInteger(GetJsonValue(json, accountnotxt));
         
         string symboltxt="symbol";
         string symbol = GetJsonValue(json, symboltxt);
         
         string magicnotxt="magicno";
         long magicno = StringToInteger(GetJsonValue(json, magicnotxt));
         
         string profittxt="profit";
         int profit = StringToInteger(GetJsonValue(json, profittxt));
         string breakeventxt="breakeven";
         int breakeven = StringToInteger(GetJsonValue(json, breakeventxt));
         Print("Extracted text=> accountno: ",accountno," symbol: ",symbol," magicno: ",magicno," profit:",profit);
         
         if((accountno==AccountInfoInteger(ACCOUNT_LOGIN) || accountno==0 ) && (symbol==_Symbol || symbol=="All" ) && (magicno==MAGIC || magicno==0 ) && profit >10 )
           {
            Print("All positions  ",_Symbol,"  closed");
            CloseAllPositions(MAGIC);
            
           }
           if((symbol==_Symbol || symbol=="All" )  && breakeven && (magicno==MAGIC || magicno==0 ))
           {
            Print("Break even activated  ",_Symbol,"  ");
            BreakEven();
           } 
         }else
            {
                Alert("Server error");
                return INIT_FAILED;
            }
      }
      
      return INIT_SUCCEEDED;
}

string GetJsonValue(const string &json, const string &key) {
   int pos = StringFind(json, "\"" + key + "\"");
   if (pos == -1) return "";

   pos = StringFind(json, ":", pos);
   if (pos == -1) return "";

   pos += 1;
   while (StringGetCharacter(json, pos) == ' ') pos++;

   bool quoted = (StringGetCharacter(json, pos) == '"');

   int start = quoted ? pos + 1 : pos;
   int end = start;

   while (end < StringLen(json)) {
      uchar ch = StringGetCharacter(json, end);
      if ((quoted && ch == '"') || (!quoted && (ch == ',' || ch == '}')))
         break;
      end++;
   }

   return StringSubstr(json, start, end - start);
}
bool StringToBool(string value)
{
   
   //value = StringToLower(value);
   Print("value: ",value);
   if(value == "true")
      return true;

   return false;
}

void BreakEven()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
      {
       if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
         //if(OrderMagicNumber()==MAGIC_NUMBER)
           {
             if(OrderType()==OP_BUY)
               {
                
                  
                   double buysl=rangeHigh; //rangehigh
                   buysl=NormalizeDouble(buysl,_Digits);
                   
                      if(OrderModify(OrderTicket(),OrderOpenPrice(),buysl,OrderTakeProfit(),OrderExpiration()))
                      {
                       Print("@@@@@@@@@@@@@@@@@@@@@@Buy Order Modified Successfuly");
                      }
                     
                  
               }else if(OrderType()==OP_SELL)
               {
                  
                     
                     double sellsl=rangeLow;//rangelow
                     sellsl=NormalizeDouble(sellsl,_Digits);
                     
                         if(OrderModify(OrderTicket(),OrderOpenPrice(),sellsl,OrderTakeProfit(),OrderExpiration()))
                           {
                            Print("@@@@@@@@@@@@@@@@@@@@@@@@Sell Order Modified Succeffuly");
                           }
                       
                   
               }
            }   
         }
      }
}

