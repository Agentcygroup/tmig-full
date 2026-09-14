#!/usr/bin/env bash
set -euo pipefail
REQ="$HOME/tmig-full/requirements.txt"
OUT="$HOME/tmig-full/requirements.d"

# Preserve any manual per-category fixes
[ -d "$OUT" ] && mv "$OUT" "$OUT.bak.$(date +%s)"
mkdir -p "$OUT"

python3 - "$REQ" "$OUT" <<'PY'
import re, sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text().splitlines()
out = pathlib.Path(sys.argv[2])
buckets, cur = {}, "misc"
for ln in src:
    m = re.match(r'^#\s*-+\s*(.+?)\s*$', ln)
    if m:
        cur = re.sub(r'[^a-z0-9]+', '-', m.group(1).lower()).strip('-')
        buckets.setdefault(cur, []); continue
    s = ln.strip()
    if s and not s.startswith('#'):
        buckets.setdefault(cur, []).append(s)
for name, pkgs in buckets.items():
    if pkgs:
        (out / f"{name}.txt").write_text("\n".join(pkgs) + "\n")
        print(f"  {name}.txt ({len(pkgs)})")
PY
