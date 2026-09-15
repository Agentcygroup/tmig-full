#!/usr/bin/env bash
# infra/check.sh — proves the infra layer is coherent.
# Exit 0 = pass. Exit non-zero = the layer is broken.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST="$(hostname -s)"
fail=0

check() { if eval "$2"; then printf '  ok   %s\n' "$1"; else printf '  FAIL %s\n' "$1"; fail=1; fi; }

echo "== infra/check.sh =="
check "README present"              "[ -f $ROOT/README.md ]"
check "policy present"              "[ -f $ROOT/policy.cedar ]"
check "host description present"    "[ -f $ROOT/hosts/${HOST}.yaml ]"
check "reconciler present"          "[ -x $ROOT/bin/reconcile ]"
check "engine present"              "[ -x $ROOT/bin/_reconcile.py ]"
check "reconciler runs (--help ok)" "$ROOT/bin/reconcile --help >/dev/null 2>&1 || [ \$? -eq 1 ]"
check "engine --help runs"          "python3 $ROOT/bin/_reconcile.py --help >/dev/null 2>&1"
check "recipes parse"               "python3 -c 'import yaml,pathlib,sys; [yaml.safe_load(p.read_text()) for p in pathlib.Path(\"$ROOT/recipes\").glob(\"*.yaml\")]'"
check "host yaml parses"            "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT/hosts/${HOST}.yaml\"))'"

if [ $fail -eq 0 ]; then
    echo "infra ok"
    exit 0
else
    echo "infra FAILED"
    exit 1
fi
