# processing/candle_builder.py
from datetime import datetime, timezone
from collections import defaultdict
import asyncpg
import os

DB_DSN = os.getenv("DATABASE_URL")
TIMEFRAME_SECONDS = {
    "1m":60, "3m":180, "5m":300, "15m":900, "30m":1800, "1h":3600, "4h":14400, "1d":86400
}

class CandleBuilder:
    def __init__(self, pool):
        self.pool = pool
        self.candles = defaultdict(dict)  # key=(symbol,tf) -> candle dict

    def bucket(self, ts, tf_s):
        epoch = int(ts.timestamp())
        return epoch - (epoch % tf_s)

    async def process_tick(self, symbol, ts_iso, price, vol):
        ts = datetime.fromisoformat(ts_iso)
        for tf, s in TIMEFRAME_SECONDS.items():
            key = (symbol, tf)
            b = self.bucket(ts, s)
            c = self.candles.get(key)
            if not c or c['bucket']!=b:
                if c:
                    await self.save_candle(symbol, tf, c)
                self.candles[key] = {'bucket':b, 'open':price,'high':price,'low':price,'close':price,'vol':vol}
            else:
                c['high']=max(c['high'], price)
                c['low']=min(c['low'], price)
                c['close']=price
                c['vol'] += vol

    async def save_candle(self, symbol, tf, c):
        ts_iso = datetime.fromtimestamp(c['bucket'], tz=timezone.utc).isoformat()
        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO candles(symbol, timeframe, timestamp, open, high, low, close, volume)
                VALUES($1,$2,$3,$4,$5,$6,$7,$8)
                ON CONFLICT (symbol,timeframe,timestamp) DO UPDATE
                SET open=EXCLUDED.open, high=EXCLUDED.high, low=EXCLUDED.low, close=EXCLUDED.close, volume=EXCLUDED.volume
            """, symbol, tf, ts_iso, c['open'], c['high'], c['low'], c['close'], c['vol'])
