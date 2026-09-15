#!/usr/bin/env bash
# Every unimplemented!/todo!/Unsupported/unreachable! in source must appear
# in OPEN.md.
set -euo pipefail
cd "$(dirname "$0")/../.."

[ -f OPEN.md ] || { echo "OPEN.md missing; run scripts/tests/open-tracking.sh --init"; exit 1; }
missing=0
while IFS=: read -r f l rest; do
    token=$(grep -oE 'unimplemented!|todo!|Unsupported|unreachable!' <<<"$rest" | head -1)
    [ -z "$token" ] && continue
    if ! grep -q "$f" OPEN.md; then
        echo "FAIL: $f:$l uses $token but is not in OPEN.md"
        missing=1
    fi
done < <(grep -rnE 'unimplemented!|todo!|Unsupported|unreachable!' crates --include='*.rs' 2>/dev/null | grep -v tests/ || true)
[ $missing -eq 0 ] && echo "open-tracking: ok" || exit 1
