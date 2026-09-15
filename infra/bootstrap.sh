#!/usr/bin/env bash
# infra/bootstrap.sh — bring a fresh machine to a state where infra/check.sh passes.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "== infra/bootstrap.sh =="

need() {
    command -v "$1" >/dev/null 2>&1 && { printf '  ok   %s\n' "$1"; return 0; }
    printf '  MISS %s\n' "$1"
    return 1
}

rc=0
need python3 || rc=1
python3 -c "import yaml" 2>/dev/null && printf '  ok   pyyaml\n' || { printf '  MISS pyyaml (pip install pyyaml)\n'; rc=1; }
need launchctl || printf '  note launchctl not present — service units will no-op\n'

echo
echo "running infra/check.sh..."
"$ROOT/check.sh" || rc=1

[ $rc -eq 0 ] && echo "bootstrap ok" || echo "bootstrap incomplete"
exit $rc
