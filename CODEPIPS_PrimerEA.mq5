//+------------------------------------------------------------------+
//|                                            CODEPIPS_PrimerEA.mq5 |
//|   EA didáctico: cruce de medias + filtro horario + riesgo en %   |
//|                                                     CODEPIPS     |
//+------------------------------------------------------------------+
//| Material educativo del ebook "Tu primer robot en MQL5".          |
//| No es una estrategia recomendada para operar en real.            |
//+------------------------------------------------------------------+
#property copyright "CODEPIPS"
#property version   "1.00"

#include <Trade\Trade.mqh>

input group "Estrategia"
input int    InpFastPeriod = 20;     // Media rápida (EMA)
input int    InpSlowPeriod = 50;     // Media lenta (EMA)
input int    InpATRPeriod  = 14;     // Periodo del ATR para el stop
input double InpATRMult    = 1.5;    // Stop = ATR x este multiplicador
input double InpRR         = 2.0;    // Take profit = stop x esta relación

input group "Riesgo y horario"
input double InpRiskPct    = 0.5;    // Riesgo por operación (% del balance)
input double InpMaxLots    = 1.0;    // Tope de lote
input int    InpStartHour  = 8;      // Hora de inicio (servidor)
input int    InpEndHour    = 17;     // Hora de fin (servidor)
input long   InpMagic      = 260001; // Número mágico

CTrade   trade;
int      hFast = INVALID_HANDLE;
int      hSlow = INVALID_HANDLE;
int      hATR  = INVALID_HANDLE;
datetime gLastBar = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpFastPeriod >= InpSlowPeriod)
   {
      Print("La media rápida debe ser menor que la lenta.");
      return INIT_PARAMETERS_INCORRECT;
   }
   hFast = iMA(_Symbol, _Period, InpFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, _Period, InpSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hATR  = iATR(_Symbol, _Period, InpATRPeriod);
   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("No se pudieron crear los indicadores. Error ", GetLastError());
      return INIT_FAILED;
   }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(20);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hATR  != INVALID_HANDLE) IndicatorRelease(hATR);
}

//--- true solo en el primer tick de cada vela nueva
bool IsNewBar()
{
   datetime t = iTime(_Symbol, _Period, 0);
   if(t != gLastBar)
   {
      gLastBar = t;
      return true;
   }
   return false;
}

//--- ¿ya hay una posición de este EA en este símbolo?
bool HasPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return true;
   }
   return false;
}

//--- lote según el riesgo en % y la distancia del stop
double LotsForRisk(double riskPct, double slDistance)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * riskPct / 100.0;
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0 || slDistance <= 0)
      return 0;

   double lots = riskMoney / ((slDistance / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lots = MathFloor(lots / step) * step;
   if(lots < minL)
      return 0;
   return MathMin(lots, MathMin(maxL, InpMaxLots));
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBar())
      return;

   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   if(t.hour < InpStartHour || t.hour >= InpEndHour)
      return;

   if(HasPosition())
      return;

   //--- valores de las 2 últimas velas cerradas: [0] = vela 1, [1] = vela 2
   double fast[], slow[], atr[];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hFast, 0, 1, 2, fast) < 2 ||
      CopyBuffer(hSlow, 0, 1, 2, slow) < 2 ||
      CopyBuffer(hATR,  0, 1, 1, atr)  < 1)
      return;

   bool crossUp   = (fast[1] <= slow[1] && fast[0] > slow[0]);
   bool crossDown = (fast[1] >= slow[1] && fast[0] < slow[0]);
   if(!crossUp && !crossDown)
      return;

   double slDist = atr[0] * InpATRMult;
   double lots   = LotsForRisk(InpRiskPct, slDist);
   if(lots <= 0)
   {
      Print("Lote calculado = 0: el riesgo mínimo supera lo permitido. No se opera.");
      return;
   }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(crossUp)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = NormalizeDouble(ask - slDist, digits);
      double tp  = NormalizeDouble(ask + slDist * InpRR, digits);
      if(!trade.Buy(lots, _Symbol, ask, sl, tp, "CODEPIPS PrimerEA"))
         Print("Compra rechazada. Código ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   }
   else
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = NormalizeDouble(bid + slDist, digits);
      double tp  = NormalizeDouble(bid - slDist * InpRR, digits);
      if(!trade.Sell(lots, _Symbol, bid, sl, tp, "CODEPIPS PrimerEA"))
         Print("Venta rechazada. Código ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   }
}
//+------------------------------------------------------------------+
