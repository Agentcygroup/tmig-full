#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/tmig-full"
TAX="$ROOT/taxonomy"
PY="$ROOT/venvs/hf/bin/python"
REC="$TAX/runtime/receipts"
mkdir -p "$REC"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "1. /Taxonomy/Docs"
"$PY" - <<'PY'
import pathlib
from pxr import Usd, Sdf, UsdGeom
p = pathlib.Path.home() / "tmig-full" / "taxonomy" / "unified.usda"
stage = Usd.Stage.Open(str(p))
if not stage.GetPrimAtPath("/Taxonomy/Docs"):
    d = UsdGeom.Scope.Define(stage, "/Taxonomy/Docs")
    tracks = {
        "Languages":   ("Natural languages + unique ML use per language", "88"),
        "PianoRecord": ("88-child piano record mapped to ML task families", "91"),
        "FHSS":        ("Frequency-hopping spread spectrum", "33"),
        "Constants":   ("SI + hyperfine physical constants", "26"),
        "Licenses":    ("82 licenses with commercial classification", "83"),
        "Sovereign":   ("11-domain sovereign substrate", "100"),
        "Host":        ("This machine: M4 Max 128GB", "19"),
        "ModelTree":   ("Base / Adapters / Finetunes / Quant / Apps / Providers", "~150"),
    }
    for name, (desc, count) in tracks.items():
        prim = UsdGeom.Xform.Define(stage, f"/Taxonomy/Docs/{name}")
        prim.GetPrim().CreateAttribute("description", Sdf.ValueTypeNames.String).Set(desc)
        prim.GetPrim().CreateAttribute("primCount", Sdf.ValueTypeNames.String).Set(count)
    meta = UsdGeom.Xform.Define(stage, "/Taxonomy/Docs/Meta")
    meta.GetPrim().CreateAttribute("version", Sdf.ValueTypeNames.String).Set("1.0.0")
    meta.GetPrim().CreateAttribute("selftest", Sdf.ValueTypeNames.String).Set("~/tmig-full/selftest.sh")
    meta.GetPrim().CreateAttribute("bootstrap", Sdf.ValueTypeNames.String).Set("~/tmig-full/bootstrap.sh")
    stage.GetRootLayer().Save()
    print(f"added /Taxonomy/Docs ({sum(1 for _ in stage.Traverse())} prims)")
else:
    print("Docs already present")
PY

say "2. policy gate"
cat > "$TAX/runtime/policy_gate.py" <<'PYEOF'
#!/usr/bin/env python3
import json, pathlib, sys
TAX = pathlib.Path.home() / "tmig-full" / "taxonomy"
LIC = TAX / "licenses" / "licenses.json"
TREE = TAX / "model-tree" / "model-tree.json"

def model_license(model):
    if not TREE.exists(): return None
    data = json.loads(TREE.read_text())
    for row in data.get("copyleft", []):
        if row.get("leaf", "").lower() in model.lower():
            return row.get("license")
    return None

def check(model, commercial=False):
    lic = model_license(model)
    if not lic: return (True, f"unknown license for {model}, allowing with warning")
    lic_id = lic.lower().replace("-","").replace("_","")
    tbl = json.loads(LIC.read_text()) if LIC.exists() else []
    row = next((r for r in tbl if r["id"].lower().replace("-","").replace("_","") == lic_id), None)
    if not row: return (True, f"license '{lic}' not in table")
    if commercial and row.get("commercial_use") == "no":
        return (False, f"REFUSED: {model} is {row['id']} — commercial_use=no")
    if row.get("copyleft") == "yes":
        return (True, f"WARN: {model} is {row['id']} (copyleft)")
    return (True, f"ok: {model} is {row['id']} (commercial_use={row['commercial_use']})")

if __name__ == "__main__":
    model = sys.argv[1] if len(sys.argv) > 1 else ""
    commercial = "--commercial" in sys.argv
    ok, msg = check(model, commercial)
    print(msg)
    sys.exit(0 if ok else 2)
PYEOF
chmod +x "$TAX/runtime/policy_gate.py"

say "3. HTTP API"
cat > "$TAX/runtime/api.py" <<'PYEOF'
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
PYEOF
chmod +x "$TAX/runtime/api.py"
lsof -ti:8090 2>/dev/null | xargs -r kill -9 2>/dev/null || true
nohup "$PY" "$TAX/runtime/api.py" > ~/.sovereign-api.log 2>&1 &
sleep 4
curl -sf --max-time 3 http://127.0.0.1:8090/health && echo " :8090 up"
