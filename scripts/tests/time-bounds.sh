#!/usr/bin/env bash
# Every script invoked by local-verify must complete within a declared
# budget. This is a smoke test: 10 minutes per script.
set -euo pipefail
cd "$(dirname "$0")/../.."

BUDGET=600
for s in policy/check.sh scripts/tests/go-xt-agree.sh scripts/tests/commit-nonclaim.sh; do
    [ -f "$s" ] || continue
    start=$(date +%s)
    timeout "$BUDGET" bash "$s" >/dev/null 2>&1 || true
    dur=$(( $(date +%s) - start ))
    if [ "$dur" -ge "$BUDGET" ]; then
        echo "FAIL: $s exceeded ${BUDGET}s (took ${dur}s)"
        exit 1
    fi
    echo "  ok   $s (${dur}s)"
done
echo "time-bounds: ok"
