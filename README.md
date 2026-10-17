# CODEPIPS Tools · Herramientas de trading algorítmico para MetaTrader 5

Herramientas educativas en **MQL5** y **Python** para programar, exportar y validar estrategias en MetaTrader 5.
Son parte de la **Ruta CODEPIPS**, una colección de 4 ebooks en español sobre trading algorítmico.

> ⚠️ **Material educativo.** Nada de este repositorio es una recomendación de inversión. El trading con apalancamiento implica alto riesgo.

## Contenido

| Archivo | Lenguaje | Qué hace |
|---|---|---|
| `CODEPIPS_PrimerEA.mq5` | MQL5 | EA didáctico: cruce de EMAs, stop por ATR, take profit por relación riesgo/beneficio, riesgo en % del balance y filtro horario. |
| `CODEPIPS_ExportTrades.mqh` | MQL5 | Exporta las operaciones cerradas de un backtest a CSV (`time, symbol, deal_type, volume, profit`). |
| `montecarlo.py` | Python 3 | Simulación Monte Carlo (permutación y bootstrap) sobre el CSV: drawdown probable y rango de resultados. |
| `ejemplo_trades.csv` | CSV | Datos de ejemplo para probar `montecarlo.py` sin MetaTrader. |

## Uso rápido

### 1. EA didáctico (MetaTrader 5)
1. Copia `CODEPIPS_PrimerEA.mq5` a `MQL5/Experts/` y `CODEPIPS_ExportTrades.mqh` a `MQL5/Include/`.
2. Ábrelo en MetaEditor y compila (F7).
3. Pruébalo en el **Probador de estrategias**, nunca directamente en real.

### 2. Exportar operaciones
Incluye el archivo en tu EA y llama a la función en `OnDeinit`:

```mql5
#include <CODEPIPS_ExportTrades.mqh>

void OnDeinit(const int reason)
{
   if(MQLInfoInteger(MQL_TESTER))
      ExportTrades("codepips_trades.csv");
}
```

El CSV queda en la carpeta común: `%APPDATA%\MetaQuotes\Terminal\Common\Files`.

### 3. Monte Carlo (Python)
Solo usa la librería estándar de Python 3.

```bash
python montecarlo.py ejemplo_trades.csv 10000 2000
#                    archivo           balance  simulaciones
```

Salida de ejemplo:

```
 Operaciones:            120
 Acierto:                39.2%
 Resultado del backtest: 1,177.61  (11.8%)
 Drawdown del backtest:  4.8%
 Drawdown máximo en 2000 secuencias (permutación):
   Mediana:              4.9%
   Peor 5%  (p95):       7.8%
   Prob. de drawdown >= 10%:   0.4%
 Resultado final (bootstrap):
   Pesimista (p5):       -162.88
   Mediana (p50):        1,159.09
   Prob. de terminar en pérdida: 7.0%
```

La idea: el drawdown de tu backtest es **una** secuencia posible. Monte Carlo te muestra cuánto podría haber sido con otro orden de operaciones, para dimensionar el riesgo antes de operar en real o en una prueba de fondeo.

## Ruta CODEPIPS (ebooks)

1. **Tu primer robot en MQL5**: de cero a un EA con gestión de riesgo.
2. **Backtest que no miente**: validación, forward test y Monte Carlo.
3. **Pasa tu prueba de fondeo con un robot**: riesgo para prop firms + EA guardián de drawdown.
4. **Tu robot 24/5**: VPS, monitoreo y alertas por Telegram.

Los libros incluyen herramientas adicionales que no están en este repositorio (guardián de drawdown PropGuard, sistema de monitoreo Heartbeat + watchdog). Disponibles en Hotmart buscando **CODEPIPS**.

## Autor

**Miguel Ángel Hernández Espinal**, Ingeniero en Sistemas · Desarrollador MQL5 y Python.
[LinkedIn](https://www.linkedin.com/in/miguel-angel-hernandez-7957a01a2/)

¿Necesitas un EA, un indicador o una automatización a medida? Escríbeme por LinkedIn.

## Licencia

[MIT](LICENSE)
