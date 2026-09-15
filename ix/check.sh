#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f endpoints.yaml ] || { echo "FAIL endpoints.yaml"; exit 1; }
[ -f schema.json ]    || { echo "FAIL schema.json";    exit 1; }
[ -x probe.sh ]       || { echo "FAIL probe.sh";       exit 1; }
python3 - <<'PY'
import json, yaml, pathlib, sys
schema = json.loads(pathlib.Path("schema.json").read_text())
eps = yaml.safe_load(pathlib.Path("endpoints.yaml").read_text())["endpoints"]
required = set(schema["required"])
for e in eps:
    missing = required - set(e.keys())
    if missing: print(f"  FAIL {e.get('name')} missing {missing}"); sys.exit(1)
print(f"  ok   {len(eps)} endpoints well-formed")
PY
echo "ix ok"
