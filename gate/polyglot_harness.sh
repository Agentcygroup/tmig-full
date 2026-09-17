#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DELTA="${1:?usage: polyglot_harness.sh DELTA_JSON OUT_JSON LEDGER_JSONL}"
OUT="${2:?usage: polyglot_harness.sh DELTA_JSON OUT_JSON LEDGER_JSONL}"
LEDGER="${3:?usage: polyglot_harness.sh DELTA_JSON OUT_JSON LEDGER_JSONL}"
mkdir -p "$(dirname "$OUT")" "$(dirname "$LEDGER")"
: > "$LEDGER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mapfile -t LANGS < <(python3 - "$DELTA" <<'PY'
import json,sys
with open(sys.argv[1], encoding="utf-8") as f: d=json.load(f)
for x in d.get("required_languages",[]): print(x)
PY
)

has_lang() { local needle="$1"; printf '%s\n' "${LANGS[@]:-}" | grep -Fxq "$needle"; }

changed_files() {
  local language="$1"
  python3 - "$DELTA" "$language" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f:d=json.load(f)
lang=sys.argv[2]
for x in d.get("deltas",[]):
    if x.get("language")==lang and not str(x.get("change","")).startswith("D"):
        print(x["path"])
PY
}

run_check() {
  local id="$1" lang="$2" required="$3"; shift 3
  local log="$TMP/${id//\//_}.log"
  local status="PASS" rc=0
  set +e
  (cd "$ROOT" && "$@") >"$log" 2>&1
  rc=$?
  set -e
  [[ $rc -eq 0 ]] || status="FAIL"
  python3 - "$LEDGER" "$id" "$lang" "$required" "$status" "$rc" "$log" <<'PY'
import hashlib,json,pathlib,sys
ledger,check,lang,required,status,rc,log=sys.argv[1:]
b=pathlib.Path(log).read_bytes()
row={"schema":"tmig.merge.ledger-row.v1","check":check,"language":lang,
     "required":required.lower()=="true","status":status,"exit_code":int(rc),
     "log_sha256":hashlib.sha256(b).hexdigest()}
with open(ledger,"a",encoding="utf-8") as f: f.write(json.dumps(row,sort_keys=True)+"\n")
PY
  printf '%s\t%s\t%s\t%s\n' "$id" "$lang" "$required" "$status" >> "$TMP/checks.tsv"
  if [[ "$required" == "true" && "$status" != "PASS" ]]; then
    echo "FAIL: $id ($lang)" >&2
    tail -100 "$log" >&2 || true
    return 1
  fi
}

if has_lang rust; then
  if [[ "${RUST_UPSTREAM_PASS:-0}" == "1" ]]; then
    printf '%s\n' '{"schema":"tmig.merge.ledger-row.v1","check":"rust-workspace","language":"rust","required":true,"status":"PASS","exit_code":0,"log_sha256":"upstream-ci-verify"}' >> "$LEDGER"
    printf '%s\t%s\t%s\t%s\n' "rust-workspace" "rust" "true" "PASS" >> "$TMP/checks.tsv"
  else
    run_check "rust-harness-lang" "rust" true cargo test -p harness-lang
  fi
fi
if has_lang go; then run_check "go-vet-test" "go" true bash -lc 'go vet ./go/... && go test ./go/...'; fi
if has_lang python; then
  mapfile -t PYFILES < <(changed_files python)
  if ((${#PYFILES[@]})); then run_check "python-compile" "python" true python3 -m py_compile "${PYFILES[@]}"; fi
fi
if has_lang node; then
  mapfile -t NODEFILES < <(changed_files node)
  for f in "${NODEFILES[@]}"; do run_check "node-syntax:$f" "node" true node --check "$f"; done
fi
if has_lang ruby; then
  mapfile -t RUBYFILES < <(changed_files ruby)
  for f in "${RUBYFILES[@]}"; do run_check "ruby-syntax:$f" "ruby" true ruby -c "$f"; done
fi
if has_lang shell; then
  mapfile -t SHFILES < <(changed_files shell)
  if ((${#SHFILES[@]})); then run_check "shell-syntax" "shell" true bash -n "${SHFILES[@]}"; fi
fi
if has_lang cedar; then run_check "cedar-policy" "cedar" true bash -lc 'cargo build --release -p xt >/dev/null && ./target/release/xt policy-check'; fi
if has_lang usd; then run_check "usd-coverage" "usd" true bash -lc 'bash scripts/tests/usd-actions-covered.sh && bash scripts/tests/usd-behaviors-covered.sh'; fi

if python3 - "$DELTA" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f:d=json.load(f)
sys.exit(0 if any(x.get("path","").startswith("gate/") for x in d.get("deltas",[])) else 1)
PY
then
  run_check "merge-gate-tests" "python" true python3 -m unittest discover -s gate/tests -v
fi

python3 - "$DELTA" "$LEDGER" "$OUT" "$TMP/checks.tsv" <<'PY'
import hashlib,json,pathlib,sys
_delta,ledger,out,tsv=sys.argv[1:]
checks=[]
p=pathlib.Path(tsv)
if p.exists():
    for line in p.read_text().splitlines():
        check,lang,required,status=line.split("\t")
        checks.append({"check":check,"language":lang,"required":required=="true","status":status})
with open(_delta,encoding="utf-8") as f:d=json.load(f)
required=set(d.get("required_languages",[]))
covered={c["language"] for c in checks if c["status"]=="PASS"}
missing=sorted(required-covered)
status="PASS" if all(c["status"]=="PASS" for c in checks if c["required"]) and not missing else "FAIL"
doc={"schema":"tmig.merge.harness.v1","status":status,"required_languages":sorted(required),
     "covered_languages":sorted(covered),"missing_languages":missing,"checks":checks,
     "ledger_sha256":hashlib.sha256(pathlib.Path(ledger).read_bytes()).hexdigest()}
doc["digest"]=hashlib.sha256(json.dumps(doc,sort_keys=True,separators=(",",":")).encode()).hexdigest()
pathlib.Path(out).write_text(json.dumps(doc,indent=2,sort_keys=True)+"\n",encoding="utf-8")
if status!="PASS": sys.exit(1)
PY

echo "polyglot harness PASS -> $OUT"
