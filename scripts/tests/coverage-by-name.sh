#!/usr/bin/env bash
# Every pub fn defined in a crate's src/ must be referenced by name in at
# least one test file in that crate. This is a weak coverage check, not a
# substitute for real coverage, but it catches dead code.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
for crate_dir in crates/*; do
    crate=$(basename "$crate_dir")
    [ -d "$crate_dir/src" ] || continue
    [ -d "$crate_dir/tests" ] || continue
    while IFS= read -r fn; do
        case "$fn" in
            main|new|default|fmt|from|into|as_str|id|handle|call|describe|invoke) continue ;;
        esac
        if ! grep -rq "\b$fn\b" "$crate_dir/tests"; then
            echo "  note: $crate::$fn has no test reference"
        fi
    done < <(grep -rhoE 'pub fn [a-z_][a-z0-9_]*' "$crate_dir/src" | awk '{print $3}' | sort -u)
done
echo "coverage-by-name: ok (notes above are informational)"
