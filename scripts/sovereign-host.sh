#!/usr/bin/env bash
# Sovereign host — M4 Max as the compute substrate for every track.
# Registers hardware, brings up one server per modality, wires the router,
# and runs an offline proof.
set -uo pipefail

# single-instance lock
VENV="${TMIG_VENV:-$HOME/.pi-venv}"
LOCK="$HOME/.sovereign-host.lock"
if [ -e "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  echo "another sovereign-host is running (pid $(cat "$LOCK")); exiting"
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

ROOT="$HOME/tmig-full"
TAX="$ROOT/taxonomy"
HOST="$TAX/host"
mkdir -p "$HOST"
PY="$VENV/bin/python"
LOG="$ROOT/receipts/sovereign-host.log"
mkdir -p "$(dirname "$LOG")"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }

# ── 1. HOST INVENTORY ─────────────────────────────────────────────
log "== host inventory =="
cat > "$HOST/host.tsv" <<'TSV'
attr	value	notes
model	MacBook Pro	Mac16,5
model_number	Z1FT000D8LL/A
chip	Apple M4 Max	16-core
cores_p	12	performance
cores_e	4	efficiency
memory_gb	128	unified
firmware	18000.161.10
serial	MY916YKY0Y
uuid	EA49ECB2-ED20-5372-BC7F-9B84A36E01F4
udid	00006041-001871A60EFA401C
activation_lock	enabled
chip_gpu_cores	40	M4 Max has 40-core GPU
neural_engine	16_core	Apple Neural Engine
memory_bandwidth_gbps	546	LPDDR5x-8533
storage_type	NVMe SSD
mlx_capable	yes	Apple silicon native
metal_capable	yes	Metal 3
ane_capable	yes	Core ML
TSV

# probe runtime capabilities
log "  probing Metal / MLX / ANE"
"$PY" - <<'PY' | tee -a "$LOG" > "$HOST/capabilities.txt"
try:
    import torch
    print("torch_mps", torch.backends.mps.is_available())
    print("torch_version", torch.__version__)
except Exception as e:
    print("torch_mps", False)

try:
    import mlx.core as mx
    print("mlx", True)
    print("mlx_device", mx.default_device())
except Exception as e:
    print("mlx", False)

try:
    import transformers
    print("transformers", transformers.__version__)
except Exception:
    print("transformers", "missing")

try:
    import diffusers
    print("diffusers", diffusers.__version__)
except Exception:
    print("diffusers", "missing")

try:
    import faster_whisper
    print("faster_whisper", True)
except Exception:
    print("faster_whisper", False)
PY

# ── 2. EMIT HOST USD ──────────────────────────────────────────────
log "== host usda =="
"$PY" - "$HOST" <<'PY'
import csv, pathlib, sys
from pxr import Usd, Sdf, UsdGeom
h = pathlib.Path(sys.argv[1])
stage = Usd.Stage.CreateNew(str(h / "host.usda"))
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
root = UsdGeom.Scope.Define(stage, "/Host")
stage.SetDefaultPrim(root.GetPrim())
for r in csv.DictReader(open(h / "host.tsv"), delimiter="\t"):
    p = UsdGeom.Xform.Define(stage, f"/Host/{r['attr']}")
    p.GetPrim().CreateAttribute("value", Sdf.ValueTypeNames.String).Set(str(r["value"]))
    p.GetPrim().CreateAttribute("notes", Sdf.ValueTypeNames.String).Set(str(r.get("notes","")))
stage.GetRootLayer().Save()
print(f"wrote {h}/host.usda ({sum(1 for _ in stage.GetPrimAtPath('/Host').GetChildren())+1} prims)")
PY

# ── 3. ONE SERVER PER MODALITY ────────────────────────────────────
log "== modality servers =="
mkdir -p "$ROOT/oss-providers"

# --- 8080 LLM (llama.cpp) ---
if lsof -ti:8080 >/dev/null 2>&1; then
  log "  :8080 already running, skip"
elif ! curl -sf http://127.0.0.1:8080/v1/models >/dev/null 2>&1; then
  if command -v llama-server >/dev/null 2>&1 || [ -x /opt/homebrew/bin/llama-server ]; then
    export PATH="/opt/homebrew/bin:$PATH"
    LLAMA=/opt/homebrew/bin/llama-server
    log "  start :8080 llama.cpp"
    nohup "$LLAMA" --models-dir "$HOME/.llama/models" \
      --host 127.0.0.1 --port 8080 --ctx-size 32768 --n-gpu-layers 999 \
      > "$HOME/.llama/router.log" 2>&1 < /dev/null &
    disown
  fi
fi

# --- 8081 embeddings (sentence-transformers) ---
if lsof -ti:8081 >/dev/null 2>&1; then
  log "  :8081 already running, skip"
elif ! curl -sf http://127.0.0.1:8081/health >/dev/null 2>&1; then
  log "  start :8081 embeddings"
  cat > "$ROOT/oss-providers/embeddings_server.py" <<'PYEOF'
#!/usr/bin/env python3
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn
app = FastAPI()
m = SentenceTransformer("BAAI/bge-small-en-v1.5")
class Req(BaseModel):
    input: list[str]
@app.post("/v1/embeddings")
def embed(r: Req):
    vecs = m.encode(r.input).tolist()
    return {"data": [{"embedding": v, "index": i} for i, v in enumerate(vecs)]}
@app.get("/health")
def health(): return {"ok": True}
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8081)
PYEOF
  nohup "$PY" "$ROOT/oss-providers/embeddings_server.py" > "$HOME/.embeddings.log" 2>&1 < /dev/null &
  disown
fi

# --- 8082 diffusers ---
if lsof -ti:8082 >/dev/null 2>&1; then
  log "  :8082 already running, skip"
elif ! curl -sf http://127.0.0.1:8082/health >/dev/null 2>&1; then
  log "  start :8082 diffusers"
  cat > "$ROOT/oss-providers/diffusers_server.py" <<'PYEOF'
#!/usr/bin/env python3
import io, os
from fastapi import FastAPI, Response
from pydantic import BaseModel
import torch
from diffusers import AutoPipelineForText2Image
app = FastAPI()
_pipe = None
def get_pipe():
    global _pipe
    if _pipe is None:
        model = os.environ.get("DIFFUSERS_MODEL", "runwayml/stable-diffusion-v1-5")
        dtype = torch.float16 if torch.backends.mps.is_available() else torch.float32
        _pipe = AutoPipelineForText2Image.from_pretrained(model, torch_dtype=dtype)
        if torch.backends.mps.is_available():
            _pipe = _pipe.to("mps")
    return _pipe
class Req(BaseModel):
    prompt: str
    steps: int = 25
    guidance: float = 7.5
@app.post("/generate")
def gen(r: Req):
    img = get_pipe()(r.prompt, num_inference_steps=r.steps, guidance_scale=r.guidance).images[0]
    buf = io.BytesIO(); img.save(buf, format="PNG")
    return Response(content=buf.getvalue(), media_type="image/png")
@app.get("/health")
def health(): return {"ok": True}
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8082)
PYEOF
  nohup "$PY" "$ROOT/oss-providers/diffusers_server.py" > "$HOME/.diffusers.log" 2>&1 < /dev/null &
  disown
fi

# --- 8083 faster-whisper ---
if lsof -ti:8083 >/dev/null 2>&1; then
  log "  :8083 already running, skip"
elif ! curl -sf http://127.0.0.1:8083/health >/dev/null 2>&1; then
  log "  start :8083 faster-whisper"
  cat > "$ROOT/oss-providers/whisper_server.py" <<'PYEOF'
#!/usr/bin/env python3
import io
from fastapi import FastAPI, UploadFile, File
from faster_whisper import WhisperModel
import uvicorn
app = FastAPI()
m = WhisperModel("base", device="auto", compute_type="int8")
@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    data = await file.read()
    segs, _ = m.transcribe(io.BytesIO(data))
    return {"text": " ".join(s.text for s in segs)}
@app.get("/health")
def health(): return {"ok": True}
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8083)
PYEOF
  nohup "$PY" "$ROOT/oss-providers/whisper_server.py" > "$HOME/.whisper.log" 2>&1 < /dev/null &
  disown
fi

# --- 8084 vision ---
if lsof -ti:8084 >/dev/null 2>&1; then
  log "  :8084 already running, skip"
elif ! curl -sf http://127.0.0.1:8084/health >/dev/null 2>&1; then
  log "  start :8084 vision"
  cat > "$ROOT/oss-providers/vision_server.py" <<'PYEOF'
#!/usr/bin/env python3
import io
from fastapi import FastAPI, UploadFile, File
from transformers import pipeline
from PIL import Image
import uvicorn
app = FastAPI()
cache = {}
@app.post("/classify")
async def classify(file: UploadFile = File(...)):
    if "cls" not in cache:
        cache["cls"] = pipeline("image-classification", model="google/vit-base-patch16-224")
    img = Image.open(io.BytesIO(await file.read()))
    return cache["cls"](img)
@app.post("/caption")
async def caption(file: UploadFile = File(...)):
    if "cap" not in cache:
        cache["cap"] = pipeline("image-to-text", model="Salesforce/blip-image-captioning-base")
    img = Image.open(io.BytesIO(await file.read()))
    return cache["cap"](img)
@app.get("/health")
def health(): return {"ok": True}
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8084)
PYEOF
  nohup "$PY" "$ROOT/oss-providers/vision_server.py" > "$HOME/.vision.log" 2>&1 < /dev/null &
  disown
fi

# ── 4. WAIT + HEALTH CHECK ────────────────────────────────────────
sleep 8
log "== health checks =="
for port in 8080 8081 8082 8083 8084; do
  if curl -sf "http://127.0.0.1:$port/health" >/dev/null 2>&1 || \
     curl -sf "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
    log "  :$port up"
  else
    log "  :$port down (see ~/.$(basename $port).log)"
  fi
done

# ── 5. ROUTER URLS ────────────────────────────────────────────────
log "== write router urls =="
cat > "$TAX/runtime/router_urls.json" <<'JSON'
{
  "llama.cpp":       "http://127.0.0.1:8080/v1",
  "ollama":          "http://127.0.0.1:11434/v1",
  "embeddings":      "http://127.0.0.1:8081/v1",
  "diffusers":       "http://127.0.0.1:8082",
  "faster-whisper":  "http://127.0.0.1:8083",
  "vision":          "http://127.0.0.1:8084",
  "vLLM":            "http://127.0.0.1:8000/v1",
  "MLX":             "http://127.0.0.1:8090/v1",
  "transformers":    "http://127.0.0.1:8084"
}
JSON
log "  wrote $TAX/runtime/router_urls.json"

# ── 6. HOOK HOST INTO UNIFIED ─────────────────────────────────────
log "== hook host into unified =="
"$PY" - <<'PY'
from pxr import Usd, UsdGeom
p = "/Users/metadusa/tmig-full/taxonomy/unified.usda"
s = Usd.Stage.Open(p)
if not s.GetPrimAtPath("/Taxonomy/Host"):
    prim = UsdGeom.Scope.Define(s, "/Taxonomy/Host")
    prim.GetPrim().GetReferences().AddReference(
        "/Users/metadusa/tmig-full/taxonomy/host/host.usda")
    s.GetRootLayer().Save()
    print(f"referenced Host ({sum(1 for _ in s.Traverse())} total prims)")
PY

# ── 7. SUMMARY ────────────────────────────────────────────────────
log "== summary =="
log "  host: $HOST/host.usda"
log "  inventory: $HOST/host.tsv"
log "  capabilities: $HOST/capabilities.txt"
log "  router urls: $TAX/runtime/router_urls.json"
log "  log: $LOG"
