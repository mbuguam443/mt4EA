
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"




input int MAGIC_NUMBER = 745363;
input string url="https://fxaccountmanager.greatjourns.com/api.php";




int OnInit()
  {
  
   
    EventSetTimer(5);
    
   return(INIT_SUCCEEDED);
  }
void OnTimer()
{
    InternetAuth();
    
}


void OnDeinit(const int reason)
  {
     EventKillTimer();
  }

void OnTick()
  {
     
      
      
      
   
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
         
         if((accountno==AccountInfoInteger(ACCOUNT_LOGIN) || accountno==0 ) && (symbol==_Symbol || symbol=="All" ) && (magicno==MAGIC_NUMBER || magicno==0 ) && profit >10 )
           {
            Print("All positions  ",_Symbol,"  closed");
            CloseAllPositions(MAGIC_NUMBER);
            
           }
           if((symbol==_Symbol || symbol=="All" )  && breakeven && (magicno==MAGIC_NUMBER || magicno==0 ))
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
                
                  
                   double buysl=92290.91; //rangehigh
                   buysl=NormalizeDouble(buysl,_Digits);
                   
                      if(OrderModify(OrderTicket(),OrderOpenPrice(),buysl,OrderTakeProfit(),OrderExpiration()))
                      {
                       Print("@@@@@@@@@@@@@@@@@@@@@@Buy Order Modified Successfuly");
                      }
                     
                  
               }else if(OrderType()==OP_SELL)
               {
                  
                     
                     double sellsl=92033.47;//rangelow
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