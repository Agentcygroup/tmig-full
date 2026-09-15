#!/usr/bin/env python3
import json, subprocess, pathlib
from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn
RUNT = pathlib.Path.home() / "tmig-full" / "taxonomy" / "runtime"
SOV = RUNT / "sovereign"
app = FastAPI(title="Sovereign API", version="1.0.0")
class RunReq(BaseModel):
    intent: str
    commercial: bool = False
@app.get("/health")
def health(): return {"ok": True}
@app.get("/resolve")
def resolve(intent: str):
    r = subprocess.run([str(SOV), "resolve", intent], capture_output=True, text=True)
    try: return json.loads(r.stdout)
    except Exception: return {"raw": r.stdout, "err": r.stderr}
@app.post("/run")
def run(req: RunReq):
    args = [str(SOV), "run", req.intent]
    if req.commercial: args.append("--commercial")
    r = subprocess.run(args, capture_output=True, text=True, timeout=300)
    return {"exit": r.returncode, "stdout": r.stdout, "stderr": r.stderr}
@app.get("/status")
def status():
    r = subprocess.run([str(SOV), "status"], capture_output=True, text=True)
    return {"status": r.stdout}
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8090)
