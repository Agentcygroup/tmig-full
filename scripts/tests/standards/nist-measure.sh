#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
fail=0
for c in crates/*; do
    [ -d "$c/tests" ] || continue
    n=$(ls "$c/tests"/*.rs 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -gt 0 ] || { echo "FAIL: $c has no tests"; fail=1; }
done
[ $fail -eq 0 ] && echo "nist-measure: ok" || exit 1
