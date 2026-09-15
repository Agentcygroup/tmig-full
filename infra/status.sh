#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST="$(hostname -s)"

printf '\n'
printf '  host:      %s\n' "$HOST"
printf '  signed:    %s\n' "$(grep -q '^\s*signed: true' "$ROOT/hosts/${HOST}.yaml" 2>/dev/null && echo yes || echo no)"
printf '  recipes:   %s\n' "$(ls "$ROOT/recipes" 2>/dev/null | wc -l | tr -d ' ')"
printf '  receipts:  %s\n' "$(ls "$ROOT/receipts" 2>/dev/null | wc -l | tr -d ' ')"
printf '  last:      %s\n' "$(ls -t "$ROOT/receipts" 2>/dev/null | head -1 || echo none)"
printf '\n'

if [ -f "$ROOT/state/${HOST}.observed" ]; then
    echo "== last observed =="
    python3 -c "
import json,sys
d=json.load(open('$ROOT/state/${HOST}.observed'))
for k,v in sorted(d.get('units',{}).items()):
    st='ok' if (v.get('present') or v.get('loaded')) else '--'
    print(f'  {st}  {k}')
"
fi
