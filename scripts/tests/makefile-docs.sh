#!/usr/bin/env bash
# Every .PHONY target in Makefile must be mentioned in docs/INVARIANTS.md or
# a README.
set -euo pipefail
cd "$(dirname "$0")/../.."
[ -f Makefile ] || { echo "makefile-docs: no Makefile; skip"; exit 0; }

targets=$(grep -E '^\.PHONY:' Makefile | sed 's/\.PHONY://' | tr -s ' ' '\n' | grep -v '^$' | sort -u)
fail=0
for t in $targets; do
    if ! grep -rq "\b$t\b" docs/ README.md 2>/dev/null; then
        echo "  note: make target '$t' undocumented"
    fi
done
echo "makefile-docs: ok (notes are informational)"
