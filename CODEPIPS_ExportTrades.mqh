//+------------------------------------------------------------------+
//|                                       CODEPIPS_ExportTrades.mqh  |
//|   Exporta las operaciones cerradas de un backtest a un CSV       |
//|                                                     CODEPIPS     |
//+------------------------------------------------------------------+
//| Uso:                                                             |
//|   1. Copia este archivo en MQL5\Include                          |
//|   2. En tu EA:   #include <CODEPIPS_ExportTrades.mqh>            |
//|   3. Dentro de OnTester():   ExportTrades();                     |
//|   4. Ejecuta UN backtest (no una optimización).                  |
//|   El CSV queda en la carpeta común de MetaTrader:                |
//|   %APPDATA%\MetaQuotes\Terminal\Common\Files                     |
//|                                                                  |
//| Nota: se exporta el resultado neto (beneficio + swap + comisión) |
//| de cada cierre. Si tu broker cobra la comisión al ENTRAR, esa    |
//| parte queda en el deal de entrada y no se incluye aquí.          |
//+------------------------------------------------------------------+

void ExportTrades(const string fileName = "codepips_trades.csv")
{
   if(!HistorySelect(0, TimeCurrent()))
   {
      Print("ExportTrades: no se pudo leer el historial.");
      return;
   }

   int h = FileOpen(fileName, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
   if(h == INVALID_HANDLE)
   {
      Print("ExportTrades: no se pudo crear el archivo. Error ", GetLastError());
      return;
   }

   FileWrite(h, "time", "symbol", "deal_type", "volume", "profit");
   int total = HistoryDealsTotal();
   int rows  = 0;
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;

      long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      double net = HistoryDealGetDouble(deal, DEAL_PROFIT) +
                   HistoryDealGetDouble(deal, DEAL_SWAP) +
                   HistoryDealGetDouble(deal, DEAL_COMMISSION);
      string type = (HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_BUY) ? "buy" : "sell";

      FileWrite(h,
                TimeToString((datetime)HistoryDealGetInteger(deal, DEAL_TIME), TIME_DATE | TIME_MINUTES),
                HistoryDealGetString(deal, DEAL_SYMBOL),
                type,
                DoubleToString(HistoryDealGetDouble(deal, DEAL_VOLUME), 2),
                DoubleToString(net, 2));
      rows++;
   }
   FileClose(h);
   Print("ExportTrades: ", rows, " operaciones guardadas en Common\\Files\\", fileName);
}
//+------------------------------------------------------------------+
