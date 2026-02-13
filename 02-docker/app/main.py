from fastapi import FastAPI
from datetime import datetime
from pathlib import Path

app = FastAPI()
DATA_DIR = Path("/data")
LOG_FILE = DATA_DIR / "visits.log"

@app.get("/")
def root():
    # This makes the volume demo real: requests write to /data/visits.log
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    LOG_FILE.write_text(LOG_FILE.read_text() + f"{datetime.utcnow().isoformat()}Z\n" if LOG_FILE.exists() else f"{datetime.utcnow().isoformat()}Z\n")
    return {"ok": True, "message": "hello from a container", "log_file": str(LOG_FILE)}

@app.get("/health")
def health():
    return {"status": "up"}
