#!/usr/bin/env bash
# Every crate with a src/ MUST be named by at least one Behavior prim,
# and every Behavior prim MUST name a crate that exists.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
for c in crates/*/; do
    name=$(basename "$c")
    [ -d "$c/src" ] || continue
    if ! grep -q "string crate = \"$name\"" spec/behaviors/behaviors.usda; then
        echo "FAIL: crate $name has no Behavior prim"
        fail=1
    fi
done
while IFS= read -r name; do
    [ -d "crates/$name/src" ] || { echo "FAIL: Behavior names missing crate $name"; fail=1; }
done < <(grep -oE 'string crate = "[a-z-]+"' spec/behaviors/behaviors.usda | sed 's/.*"\(.*\)"/\1/' | sort -u)

[ $fail -eq 0 ] && echo "usd-behaviors-covered: ok" || exit 1
