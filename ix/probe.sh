#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
python3 - <<'PY'
import yaml, subprocess, sys, pathlib
eps = yaml.safe_load(pathlib.Path("endpoints.yaml").read_text())["endpoints"]
fail = 0
for e in eps:
    url = f"http://127.0.0.1:{e['port']}{e['health']}"
    r = subprocess.run(["curl","-sf","--max-time","3",url], capture_output=True)
    if r.returncode == 0: print(f"  ok    :{e['port']} {e['name']}")
    else:                 print(f"  down  :{e['port']} {e['name']}  {url}"); fail = 1
sys.exit(fail)
PY
