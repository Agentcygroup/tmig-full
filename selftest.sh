#!/usr/bin/env bash
# Sovereign selftest. Exit 0 only if every modality works.
set -uo pipefail
ROOT="$HOME/tmig-full"
PY="$ROOT/venvs/hf/bin/python"
FAIL=0
pass() { printf '  ok   %s\n' "$*"; }
fail() { printf '  FAIL %s\n' "$*"; FAIL=1; }

# 1. servers
for port in 8080 8081 8082 8083 8084; do
  if curl -sf --max-time 3 "http://127.0.0.1:$port/health" >/dev/null 2>&1 || \
     curl -sf --max-time 3 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
    pass "server :$port"
  else
    fail "server :$port down"
  fi
done

# 2. inference per modality
out=$(curl -s --max-time 60 -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen2.5-coder-3b-instruct-q4_k_m","messages":[{"role":"user","content":"respond with the single word OK"}],"max_tokens":5}' \
  | jq -r '.choices[0].message.content // empty')
[ -n "$out" ] && pass "llm inference" || fail "llm inference"

out=$(curl -s --max-time 30 -X POST http://127.0.0.1:8081/v1/embeddings \
  -H 'Content-Type: application/json' -d '{"input":["selftest"]}' \
  | jq '.data[0].embedding | length')
[ "$out" = "384" ] && pass "embeddings (dim=$out)" || fail "embeddings (got=$out)"

"$PY" -c "
import requests, io, numpy as np, soundfile as sf, tempfile
f = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
sf.write(f.name, np.zeros(16000, dtype=np.float32), 16000)
r = requests.post('http://127.0.0.1:8083/transcribe', files={'file': open(f.name,'rb')}, timeout=60)
assert r.status_code == 200, r.status_code
" 2>/dev/null && pass "asr" || fail "asr"

"$PY" -c "
import requests, io
from PIL import Image
img = Image.new('RGB', (224,224), (128,128,128))
buf = io.BytesIO(); img.save(buf, 'PNG'); buf.seek(0)
r = requests.post('http://127.0.0.1:8084/classify', files={'file': buf}, timeout=60)
assert r.status_code == 200, r.status_code
" 2>/dev/null && pass "vision" || fail "vision"

# 3. unified stage opens
"$PY" -c "
from pxr import Usd
s = Usd.Stage.Open('$ROOT/taxonomy/unified.usda')
assert s.GetDefaultPrim(), 'no defaultPrim'
" 2>/dev/null && pass "unified.usda opens" || fail "unified.usda"

# 4. receipt chain
"$PY" "$ROOT/taxonomy/runtime/receipt.py" verify 2>/dev/null \
  | grep -q '"broken": 0' && pass "receipt chain" || fail "receipt chain"

# 5. disk headroom
free=$(df -g "$HOME" | awk 'NR==2 {print $4}')
[ "$free" -gt 20 ] && pass "disk free ${free}GB" || fail "disk free ${free}GB (< 20)"

exit $FAIL
