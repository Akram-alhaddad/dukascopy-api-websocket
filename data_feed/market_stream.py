# data_feed/market_stream.py
import os, asyncio, json, traceback, time
from datetime import datetime, timezone
import asyncpg
import websockets
from dotenv import load_dotenv

load_dotenv()

PROXY_WS = os.getenv("PROXY_WS_URL") or os.getenv("DUKASCOPY_WS_URL")
DB_DSN = os.getenv("DATABASE_URL")
BATCH_SIZE = int(os.getenv("TICK_BATCH_SIZE", "500"))
BATCH_INTERVAL = float(os.getenv("BATCH_INTERVAL", "1.0"))
MAX_QUEUE = int(os.getenv("MAX_QUEUE", "20000"))

queue = asyncio.Queue(maxsize=MAX_QUEUE)

def now_iso():
    return datetime.now(timezone.utc).isoformat()

def normalize(msg_text):
    try:
        d = json.loads(msg_text)
    except Exception:
        return None
    # try many shapes
    symbol = d.get("symbol") or d.get("instrument") or d.get("pair") or d.get("s")
    if symbol and "/" in symbol: symbol = symbol.replace("/", "")
    bid = d.get("bid") or d.get("b") or d.get("price")
    ask = d.get("ask") or d.get("a") or (d.get("price") and d.get("price"))
    vol = d.get("volume") or d.get("v") or d.get("size") or 0
    ts = d.get("timestamp") or d.get("ts") or d.get("time") or None
    try:
        if ts:
            ts = int(ts)
            ts_iso = datetime.fromtimestamp(ts/1000, tz=timezone.utc).isoformat() if ts>10**12 else datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()
        else:
            ts_iso = now_iso()
    except:
        ts_iso = now_iso()
    if not symbol or (bid is None and ask is None):
        return None
    if bid is None: bid = ask
    if ask is None: ask = bid
    try:
        bid = float(bid); ask = float(ask); vol = float(vol)
    except:
        pass
    return (symbol, ts_iso, bid, ask, vol)

async def pg_pool():
    return await asyncpg.create_pool(dsn=DB_DSN, min_size=1, max_size=10)

async def writer_worker(pool):
    buffer = []
    last_flush = time.time()
    while True:
        item = await queue.get()
        buffer.append(item)
        if len(buffer) >= BATCH_SIZE or (time.time()-last_flush)>=BATCH_INTERVAL:
            records = [(r[0], r[1], r[2], r[3], r[4]) for r in buffer]
            buffer = []
            last_flush = time.time()
            async with pool.acquire() as conn:
                try:
                    await conn.copy_records_to_table('ticks', records=records, columns=['symbol','timestamp','bid','ask','volume'])
                except Exception:
                    for rec in records:
                        try:
                            await conn.execute("INSERT INTO ticks(symbol,timestamp,bid,ask,volume) VALUES($1,$2,$3,$4,$5)", *rec)
                        except Exception as e:
                            print("insert err:", e)
        queue.task_done()

async def ws_consumer():
    pool = await pg_pool()
    workers = [asyncio.create_task(writer_worker(pool)) for _ in range(2)]
    backoff = 1
    while True:
        try:
            async with websockets.connect(PROXY_WS, max_size=None) as ws:
                print("connected to", PROXY_WS)
                # optional subscribe message
                sub = os.getenv("PROXY_SUBSCRIBE_MESSAGE")
                if sub:
                    await ws.send(sub)
                async for msg in ws:
                    n = normalize(msg)
                    if n:
                        try:
                            await queue.put(n)
                        except asyncio.QueueFull:
                            _ = queue.get_nowait()  # drop oldest
                            await queue.put(n)
        except Exception as e:
            print("ws err:", e)
            traceback.print_exc()
            await asyncio.sleep(backoff)
            backoff = min(backoff*2, 60)

if __name__ == "__main__":
    asyncio.run(ws_consumer())
