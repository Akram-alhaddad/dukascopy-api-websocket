# api/main.py
import os, asyncio, json
from fastapi import FastAPI, WebSocket, Depends, HTTPException
import asyncpg
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()
app = FastAPI(title="Market API")

origins = os.getenv("CORS_ORIGINS","*")
if origins == "*":
    allow_origins = ["*"]
else:
    allow_origins = [o.strip() for o in origins.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_DSN = os.getenv("DATABASE_URL")

@app.on_event("startup")
async def startup():
    app.state.pool = await asyncpg.create_pool(dsn=DB_DSN, min_size=1, max_size=10)
    app.state.subscribers = set()

@app.on_event("shutdown")
async def shutdown():
    await app.state.pool.close()

@app.get("/api/v1/candles/{symbol}/{timeframe}")
async def get_candles(symbol: str, timeframe: str, limit: int = 200):
    pool = app.state.pool
    rows = await pool.fetch(
        "SELECT timestamp, open, high, low, close, volume FROM candles WHERE symbol=$1 AND timeframe=$2 ORDER BY timestamp DESC LIMIT $3",
        symbol, timeframe, limit
    )
    return [dict(r) for r in rows]

@app.websocket("/ws/market")
async def ws_market(ws: WebSocket):
    await ws.accept()
    app.state.subscribers.add(ws)
    try:
        while True:
            await asyncio.sleep(60)  # placeholder; actual pushes from collector via Redis/pubsub
    except Exception:
        pass
    finally:
        app.state.subscribers.remove(ws)
        await ws.close()
