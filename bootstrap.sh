#!/usr/bin/env bash
# One bootstrap. Clean checkout → working stack. Idempotent.
set -euo pipefail

ROOT="$HOME/tmig-full"
TAX="$ROOT/taxonomy"
PY="$ROOT/venvs/hf/bin/python"
HF="$ROOT/venvs/hf/bin/hf"
LOG="$ROOT/receipts/bootstrap.log"
mkdir -p "$ROOT/receipts" "$TAX"
exec > >(tee -a "$LOG") 2>&1

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()  { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mFAIL\033[0m %s\n' "$*" >&2; exit 1; }

# 0. prerequisite check
say "prerequisites"
for t in git python3 cargo rustc brew curl; do
  command -v "$t" >/dev/null 2>&1 || die "missing: $t"
done
ok "tools present"

# 1. Python venv
say "python venv"
[ -x "$PY" ] || python3 -m venv "$ROOT/venvs/hf"
"$PY" -m pip install --upgrade pip -q
"$PY" -m pip install -q \
  "huggingface_hub[cli]" transformers accelerate datasets \
  sentencepiece protobuf safetensors torch torchvision torchaudio \
  numpy pandas scipy scikit-learn usd-core \
  fastapi uvicorn pydantic sentence-transformers faster-whisper diffusers \
  stable-baselines3 gymnasium torch-geometric pyannote.audio
ok "venv ready"

# 2. Rust workspace
say "cargo build"
( cd "$ROOT" && cargo build --release --workspace -q )
ok "xt built"

# 3. HF auth
say "hf auth"
if ! "$HF" auth whoami >/dev/null 2>&1; then
  warn "not logged in — run: $HF auth login"
else
  ok "authenticated as $("$HF" auth whoami 2>/dev/null | tail -1 | tr -d ' ')"
fi

# 4. Compose USD tracks from TSV sources
say "compose USD"

# 4a. languages
if [ -f "$TAX/languages/languages.tsv" ]; then
  bash ~/language-taxonomy.sh emit-lx >/dev/null
  bash ~/language-taxonomy.sh emit-json >/dev/null
  bash ~/language-taxonomy.sh emit-usda >/dev/null
  ok "languages composed"
fi

# 4b. piano-record
if [ -f "$TAX/piano-record/record.tsv" ] || [ -f "$TAX/piano-record/mapping.tsv" ]; then
  bash ~/piano-record-map.sh >/dev/null
  ok "piano-record composed"
fi

# 4c. fhss
if [ -f "$TAX/fhss/bands.tsv" ]; then
  bash ~/fhss-map.sh >/dev/null
  ok "fhss composed"
fi

# 4d. constants
if [ -f "$TAX/constants/si.tsv" ]; then
  bash ~/constants.sh >/dev/null
  ok "constants composed"
fi

# 4e. licenses
if [ -f "$TAX/licenses/licenses.tsv" ]; then
  bash ~/licenses.sh >/dev/null
  ok "licenses composed"
fi

# 4f. sovereign (domains)
if [ -d "$TAX/sovereign" ] && ls "$TAX/sovereign"/*.tsv >/dev/null 2>&1; then
  "$PY" - "$TAX" <<'PY'
import csv, pathlib, sys
from pxr import Usd, Sdf, UsdGeom
tax = pathlib.Path(sys.argv[1])
sov = tax / "sovereign"
stage = Usd.Stage.CreateNew(str(sov / "sovereign.usda"))
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
root = UsdGeom.Scope.Define(stage, "/Sovereign")
stage.SetDefaultPrim(root.GetPrim())
def safe(n):
    s = "".join(c if c.isalnum() or c == "_" else "_" for c in str(n))
    return ("v_"+s) if (not s or s[0].isdigit()) else s
for tsv in sorted(sov.glob("*.tsv")):
    UsdGeom.Scope.Define(stage, f"/Sovereign/{safe(tsv.stem)}")
    lines = tsv.read_text().splitlines()
    if not lines: continue
    hdr = lines[0].split("\t")
    for i, line in enumerate(lines[1:]):
        parts = line.split("\t")
        if len(parts) < len(hdr):
            parts += [""] * (len(hdr) - len(parts))
        row = dict(zip(hdr, parts))
        name = (row.get("name") or row.get("attr") or row.get("system")
                or row.get("class") or row.get("layer") or row.get("domain")
                or row.get("era") or row.get("iso3166") or row.get("jurisdiction")
                or row.get("instrument") or row.get("event") or f"row_{i}")
        p = UsdGeom.Xform.Define(stage, f"/Sovereign/{safe(tsv.stem)}/{safe(name)}")
        for k, v in row.items():
            p.GetPrim().CreateAttribute(safe(k), Sdf.ValueTypeNames.String).Set(str(v))
stage.GetRootLayer().Save()
print(f"sovereign: {sum(1 for _ in stage.Traverse())} prims")
PY
  ok "sovereign composed"
fi

# 4g. host
if [ -f "$TAX/host/host.tsv" ]; then
  "$PY" - "$TAX" <<'PY'
import csv, pathlib, sys
from pxr import Usd, Sdf, UsdGeom
h = pathlib.Path(sys.argv[1]) / "host"
stage = Usd.Stage.CreateNew(str(h / "host.usda"))
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
root = UsdGeom.Scope.Define(stage, "/Host")
stage.SetDefaultPrim(root.GetPrim())
for r in csv.DictReader(open(h / "host.tsv"), delimiter="\t"):
    p = UsdGeom.Xform.Define(stage, f"/Host/{r['attr']}")
    p.GetPrim().CreateAttribute("value", Sdf.ValueTypeNames.String).Set(str(r["value"]))
    p.GetPrim().CreateAttribute("notes", Sdf.ValueTypeNames.String).Set(str(r.get("notes","")))
stage.GetRootLayer().Save()
print(f"host: {sum(1 for _ in stage.Traverse())} prims")
PY
  ok "host composed"
fi

# 4h. model-tree
if [ -f "$TAX/model-tree/tree.tsv" ]; then
  bash ~/model-tree.sh >/dev/null 2>&1 || warn "model-tree script issue (non-fatal)"
  ok "model-tree attempted"
fi

# 5. compose unified
say "unified.usda"
rm -f "$TAX/unified.usda"
"$PY" - "$TAX" <<'PY'
import pathlib, sys
from pxr import Usd, UsdGeom
tax = pathlib.Path(sys.argv[1])
out = tax / "unified.usda"
stage = Usd.Stage.CreateNew(str(out))
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
root = UsdGeom.Scope.Define(stage, "/Taxonomy")
stage.SetDefaultPrim(root.GetPrim())

refs = [
    ("Languages",   tax / "languages" / "languages.usda"),
    ("PianoRecord", tax / "piano-record" / "record.usda"),
    ("FHSS",        tax / "fhss" / "fhss.usda"),
    ("Constants",   tax / "constants" / "constants.usda"),
    ("Licenses",    tax / "licenses" / "licenses.usda"),
    ("Sovereign",   tax / "sovereign" / "sovereign.usda"),
    ("Host",        tax / "host" / "host.usda"),
    ("ModelTree",   tax / "model-tree" / "model-tree.usda"),
]
for name, path in refs:
    if path.exists():
        p = UsdGeom.Scope.Define(stage, f"/Taxonomy/{name}")
        p.GetPrim().GetReferences().AddReference(str(path))
        print(f"  referenced {name}")
    else:
        print(f"  skipped {name} (missing)")
stage.GetRootLayer().Save()
print(f"unified: {sum(1 for _ in stage.Traverse())} prims")
PY

# 6. start servers
say "modality servers"
bash "$HOME/sovereign-host.sh" >/dev/null 2>&1 || warn "sovereign-host returned non-zero"

# 7. selftest
say "selftest"
bash "$HOME/tmig-full/selftest.sh"

say "bootstrap complete"
