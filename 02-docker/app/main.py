import os
from datetime import UTC, datetime
from pathlib import Path

import redis
from fastapi import FastAPI

app = FastAPI()
DATA_DIR = Path("/data")
LOG_FILE = DATA_DIR / "visits.log"

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
cache = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


@app.get("/")
def root():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(UTC).isoformat()
    LOG_FILE.write_text(
        LOG_FILE.read_text() + f"{timestamp}\n" if LOG_FILE.exists() else f"{timestamp}\n"
    )
    visits = cache.incr("visit_count")
    return {
        "ok": True,
        "message": "hello from a container",
        "visits": visits,
        "log_file": str(LOG_FILE),
    }


@app.get("/health")
def health():
    try:
        cache.ping()
        redis_status = "connected"
    except redis.ConnectionError:
        redis_status = "disconnected"
    return {"status": "up", "redis": redis_status}
