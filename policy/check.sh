#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "== policy/check.sh =="
for f in schema.cedar.json principals.cedar actions.cedar resources.cedar; do
    [ -f "$f" ] || { echo "FAIL missing $f"; exit 1; }
    echo "  ok   $f"
done
for f in rules/*.cedar; do
    [ -f "$f" ] || { echo "FAIL missing rule"; exit 1; }
    echo "  ok   $f"
done
[ -f tests/decision-table.json ] || { echo "FAIL decision table"; exit 1; }
[ -x run-tests.sh ] || { echo "FAIL run-tests.sh"; exit 1; }
bash -n run-tests.sh

python3 - <<'PY'
import json, pathlib, sys
table = json.loads(pathlib.Path("tests/decision-table.json").read_text())
rows = table.get("rows", [])
if len(rows) < 15:
    print(f"FAIL: decision table has {len(rows)} rows, need >= 15"); sys.exit(1)
required = {"id", "principal", "action", "resource", "context", "expect"}
for r in rows:
    missing = required - set(r.keys())
    if missing:
        print(f"FAIL row {r.get('id','?')} missing {missing}"); sys.exit(1)
    if r["expect"] not in ("allow", "deny"):
        print(f"FAIL row {r['id']} has invalid expect"); sys.exit(1)
print(f"  ok   decision table: {len(rows)} rows")
PY

bash run-tests.sh
echo "policy ok"
