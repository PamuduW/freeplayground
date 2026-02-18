from fastapi import FastAPI
from datetime import datetime, timezone
from pathlib import Path

app = FastAPI()
DATA_DIR = Path("/data")
LOG_FILE = DATA_DIR / "visits.log"

@app.get("/")
def root():
    # This makes the volume demo real: requests write to /data/visits.log
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).isoformat()
    LOG_FILE.write_text(LOG_FILE.read_text() + f"{timestamp}\n" if LOG_FILE.exists() else f"{timestamp}\n")
    return {"ok": True, "message": "hello from a container", "log_file": str(LOG_FILE)}

@app.get("/health")
def health():
    return {"status": "up"}
