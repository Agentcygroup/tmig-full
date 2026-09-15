#!/usr/bin/env bash
# If a tool mentions policy/schema.cedar.json in code, the file must exist.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
while IFS=: read -r f l rest; do
    for path in $(grep -oE '"[^"]*\.cedar\.json"' <<<"$rest" | tr -d '"'); do
        if [ ! -f "$path" ]; then
            echo "FAIL: $f:$l references missing $path"
            fail=1
        fi
    done
done < <(grep -rn '\.cedar\.json' crates --include='*.rs' 2>/dev/null || true)
[ $fail -eq 0 ] && echo "schema-presence: ok" || exit 1
