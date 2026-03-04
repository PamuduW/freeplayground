import os
from datetime import UTC, datetime
from pathlib import Path

from fastapi import FastAPI

app = FastAPI()
DATA_DIR = Path("/data")
LOG_FILE = DATA_DIR / "visits.log"

# Redis is optional — the app works standalone (file-only counting) or with
# Compose (Redis-backed counting).  Set REDIS_HOST to enable Redis mode.
cache = None
try:
    import redis

    REDIS_HOST = os.getenv("REDIS_HOST")
    if REDIS_HOST:
        REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
        cache = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
        cache.ping()
except Exception:
    cache = None

_local_visit_count = 0


@app.get("/")
def root():
    global _local_visit_count
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(UTC).isoformat()
    LOG_FILE.write_text(
        LOG_FILE.read_text() + f"{timestamp}\n" if LOG_FILE.exists() else f"{timestamp}\n"
    )

    if cache:
        try:
            visits = cache.incr("visit_count")
        except Exception:
            _local_visit_count += 1
            visits = _local_visit_count
    else:
        _local_visit_count += 1
        visits = _local_visit_count

    return {
        "ok": True,
        "message": "hello from a container",
        "visits": visits,
        "log_file": str(LOG_FILE),
    }


@app.get("/health")
def health():
    redis_status = "not configured"
    if cache:
        try:
            cache.ping()
            redis_status = "connected"
        except Exception:
            redis_status = "disconnected"
    return {"status": "up", "redis": redis_status}
