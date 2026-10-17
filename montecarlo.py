"""
CODEPIPS - Monte Carlo para resultados de backtest
--------------------------------------------------
Uso:
    python montecarlo.py codepips_trades.csv 10000
        (archivo CSV exportado con CODEPIPS_ExportTrades.mqh, balance inicial)

Opcionales:
    python montecarlo.py trades.csv 10000 5000
        (tercer argumento = número de simulaciones, por defecto 5000)

Qué hace:
  1. Permutación: reordena las mismas operaciones al azar miles de veces.
     El resultado final es igual, pero el drawdown cambia según el orden.
     Te dice qué drawdown podrías haber sufrido con otra secuencia.
  2. Bootstrap: toma operaciones al azar CON reemplazo.
     Te da un rango de resultados finales posibles.

Solo usa la librería estándar de Python 3. Material educativo.
"""
import csv
import random
import sys


def load_profits(path):
    profits = []
    with open(path, newline="", encoding="utf-8-sig", errors="replace") as fh:
        for row in csv.DictReader(fh):
            try:
                profits.append(float(row["profit"]))
            except (KeyError, ValueError):
                continue
    return profits


def max_drawdown_pct(seq, start):
    equity = peak = start
    worst = 0.0
    for p in seq:
        equity += p
        peak = max(peak, equity)
        if peak > 0:
            worst = max(worst, (peak - equity) / peak)
    return worst * 100.0


def pct(values, q):
    s = sorted(values)
    k = min(len(s) - 1, max(0, int(round(q / 100.0 * (len(s) - 1)))))
    return s[k]


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    path = sys.argv[1]
    start = float(sys.argv[2])
    runs = int(sys.argv[3]) if len(sys.argv) > 3 else 5000

    profits = load_profits(path)
    if len(profits) < 30:
        print(f"Solo hay {len(profits)} operaciones. Con menos de 30 el análisis no es fiable.")
        if not profits:
            sys.exit(1)

    random.seed(42)
    original_dd = max_drawdown_pct(profits, start)
    dds = []
    finals = []
    for _ in range(runs):
        shuffled = random.sample(profits, len(profits))
        dds.append(max_drawdown_pct(shuffled, start))
        boot = [random.choice(profits) for _ in profits]
        finals.append(sum(boot))

    total = sum(profits)
    wins = sum(1 for p in profits if p > 0)
    print("=" * 56)
    print(" CODEPIPS Monte Carlo")
    print("=" * 56)
    print(f" Operaciones:            {len(profits)}")
    print(f" Acierto:                {wins / len(profits) * 100:.1f}%")
    print(f" Resultado del backtest: {total:,.2f}  ({total / start * 100:.1f}%)")
    print(f" Drawdown del backtest:  {original_dd:.1f}%")
    print("-" * 56)
    print(f" Drawdown máximo en {runs} secuencias (permutación):")
    print(f"   Mediana:              {pct(dds, 50):.1f}%")
    print(f"   Peor 10% (p90):       {pct(dds, 90):.1f}%")
    print(f"   Peor 5%  (p95):       {pct(dds, 95):.1f}%")
    print(f"   Peor 1%  (p99):       {pct(dds, 99):.1f}%")
    for limit in (5, 8, 10, 15, 20):
        prob = sum(1 for d in dds if d >= limit) / runs * 100
        print(f"   Prob. de drawdown >= {limit:>2}%: {prob:5.1f}%")
    print("-" * 56)
    print(" Resultado final (bootstrap):")
    print(f"   Pesimista (p5):       {pct(finals, 5):,.2f}")
    print(f"   Mediana (p50):        {pct(finals, 50):,.2f}")
    print(f"   Optimista (p95):      {pct(finals, 95):,.2f}")
    neg = sum(1 for f in finals if f <= 0) / runs * 100
    print(f"   Prob. de terminar en pérdida: {neg:.1f}%")
    print("=" * 56)


if __name__ == "__main__":
    main()
