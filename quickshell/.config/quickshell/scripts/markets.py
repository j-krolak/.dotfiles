#!/usr/bin/env python3
"""Live prices as one JSON object on stdout, polled by MarketsState.qml.

What is shown comes from ../markets.json: a list of tabs, each a list of
symbols. "yahoo" tabs use Yahoo Finance's unofficial chart endpoint (stocks,
indices like ^GSPC, futures like GC=F, crypto as BTC-USD via "suffix"), "fx"
tabs use Frankfurter (ECB rates, daily, quoted against "quote"). No API keys.

Also `chart TICKER RANGE KIND` (longer history for one row) and
`edit add|remove TAB SYMBOL` (used by the panel's add/remove buttons).
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone

CONFIG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "markets.json")


def load():
    with open(CONFIG) as f:
        return json.load(f)


QUOTE = load().get("quote", "PLN")


def quote(ticker):
    return urllib.parse.quote(ticker, safe="")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=8))


def thin(values, n=48):
    values = [v for v in values if v is not None]
    if len(values) <= n:
        return values
    step = (len(values) - 1) / (n - 1)
    return [values[round(i * step)] for i in range(n)]


def series(result, n=48):
    """(timestamps, closes) from a Yahoo chart result, gaps dropped and thinned to n points."""
    pairs = [(t, c) for t, c in zip(result.get("timestamp") or [], result["indicators"]["quote"][0]["close"]) if c is not None]
    if len(pairs) > n:
        step = (len(pairs) - 1) / (n - 1)
        pairs = [pairs[round(i * step)] for i in range(n)]
    return [t for t, _ in pairs], [c for _, c in pairs]


def stock(ticker, symbol=None, name=None, cur=None):
    try:
        meta = get(f"https://query1.finance.yahoo.com/v8/finance/chart/{quote(ticker)}?interval=5m&range=1d")
        times, spark = series(meta["chart"]["result"][0])
        meta = meta["chart"]["result"][0]["meta"]
        price = meta["regularMarketPrice"]
        prev = meta.get("chartPreviousClose") or meta.get("previousClose")
        change = meta.get("regularMarketChangePercent")
        if change is None and prev:
            change = (price / prev - 1) * 100
        stats = []
        def num(x, d=2):
            return f"{x:,.{d}f}" if x >= 1 else f"{x:.4f}"
        if prev:
            stats.append(["Prev close", num(prev)])
        if meta.get("regularMarketDayLow") and meta.get("regularMarketDayHigh"):
            stats.append(["Day range", f"{num(meta['regularMarketDayLow'])} – {num(meta['regularMarketDayHigh'])}"])
        if meta.get("fiftyTwoWeekLow") and meta.get("fiftyTwoWeekHigh"):
            stats.append(["52w range", f"{num(meta['fiftyTwoWeekLow'])} – {num(meta['fiftyTwoWeekHigh'])}"])
        vol = meta.get("regularMarketVolume")
        if vol:
            stats.append(["Volume", f"{vol / 1e9:.2f}B" if vol >= 1e9 else f"{vol / 1e6:.1f}M" if vol >= 1e6 else f"{vol:,}"])
        # A custom name from markets.json is the title and the symbol moves under it.
        sym = symbol or ticker
        return {"symbol": name or sym, "ticker": ticker, "stats": stats,
                "name": sym if name else meta.get("shortName") or meta.get("longName") or ticker,
                "price": price, "change": change, "currency": meta.get("currency", "USD") if cur is None else cur,
                "spark": spark, "times": times}
    except Exception:
        return None


def day_ts(day):
    return int(datetime.strptime(day, "%Y-%m-%d").replace(tzinfo=timezone.utc).timestamp())


def currency(code):
    try:
        start = (date.today() - timedelta(days=30)).isoformat()
        rates = get(f"https://api.frankfurter.dev/v1/{start}..?base={code}&symbols={QUOTE}")["rates"]
        days = sorted(rates)
        price = rates[days[-1]][QUOTE]
        prev = rates[days[-2]][QUOTE] if len(days) > 1 else price
        return {"symbol": code, "ticker": code, "name": f"{code}/{QUOTE}", "price": price,
                "change": (price / prev - 1) * 100 if prev else 0, "currency": QUOTE,
                "spark": [rates[d][QUOTE] for d in days], "times": [day_ts(d) for d in days],
                "stats": [["Prev", f"{prev:.4f}"], ["30d low", f"{min(r[QUOTE] for r in rates.values()):.4f}"],
                          ["30d high", f"{max(r[QUOTE] for r in rates.values()):.4f}"]]}
    except Exception:
        return None


def chart(ticker, span, kind):
    """Longer history for one row, fetched when it is expanded."""
    if kind == "fx":
        days = {"1M": 30, "3M": 91, "1Y": 365}[span]
        start = (date.today() - timedelta(days=days)).isoformat()
        rates = get(f"https://api.frankfurter.dev/v1/{start}..?base={ticker}&symbols={QUOTE}")["rates"]
        ds = sorted(rates)
        step = max(1, len(ds) // 80)
        ds = ds[::step] + ([ds[-1]] if (len(ds) - 1) % step else [])
        return [day_ts(d) for d in ds], [rates[d][QUOTE] for d in ds]
    rng, interval = {"1D": ("1d", "5m"), "1M": ("1mo", "1d"), "1Y": ("1y", "1d")}[span]
    r = get(f"https://query1.finance.yahoo.com/v8/finance/chart/{quote(ticker)}?interval={interval}&range={rng}")
    return series(r["chart"]["result"][0], 80)


def edit(action, tab_id, symbol):
    config = load()
    tab = next((t for t in config["tabs"] if t["id"] == tab_id), None)
    if not tab:
        return {"ok": False, "error": "no such tab"}
    symbol = symbol.strip().upper() if tab["type"] == "yahoo" or tab["type"] == "fx" else symbol.strip()
    if not symbol:
        return {"ok": False, "error": "empty symbol"}
    key = lambda i: (i["s"] if isinstance(i, dict) else i).upper()
    if action == "remove":
        tab["items"] = [i for i in tab["items"] if key(i) != symbol]
    else:
        if any(key(i) == symbol for i in tab["items"]):
            return {"ok": False, "error": "already on the list"}
        check = currency(symbol) if tab["type"] == "fx" else stock(symbol + tab.get("suffix", ""))
        if not check:
            return {"ok": False, "error": "unknown symbol"}
        tab["items"].append(symbol)
    with open(CONFIG, "w") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return {"ok": True}


if len(sys.argv) == 5 and sys.argv[1] == "chart":
    try:
        times, points = chart(sys.argv[2], sys.argv[3], sys.argv[4])
        print(json.dumps({"symbol": sys.argv[2], "range": sys.argv[3], "points": points, "times": times}))
    except Exception:
        print(json.dumps({"symbol": sys.argv[2], "range": sys.argv[3], "points": [], "times": []}))
    sys.exit()

if len(sys.argv) == 5 and sys.argv[1] == "edit":
    print(json.dumps(edit(sys.argv[2], sys.argv[3], sys.argv[4])))
    sys.exit()


def fetch(tab, item):
    sym, name = (item["s"], item.get("n")) if isinstance(item, dict) else (item, None)
    if tab["type"] == "fx":
        return currency(sym)
    suffix = tab.get("suffix", "")
    return stock(sym + suffix, sym, name, tab.get("currency"))


config = load()
with ThreadPoolExecutor(12) as pool:
    jobs = [(t, [pool.submit(fetch, t, i) for i in t["items"]]) for t in config["tabs"]]
    out = {
        "updated": int(time.time()),
        "tabs": [{"id": t["id"], "label": t["label"], "type": t["type"], "suffix": t.get("suffix", ""), "items": [r for r in (f.result() for f in fs) if r]}
                 for t, fs in jobs],
    }

print(json.dumps(out))
