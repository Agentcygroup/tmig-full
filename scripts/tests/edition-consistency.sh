#!/usr/bin/env bash
# All crates must resolve to the same Rust edition. Handles both literal
# `edition = "X"` and `edition.workspace = true` (inherits workspace).
set -euo pipefail
cd "$(dirname "$0")/../.."

ws_edition=$(grep -A5 '^\[workspace.package\]' Cargo.toml | grep -oE 'edition *= *"[^"]+"' | grep -oE '"[^"]+"' | tr -d '"' | head -1)
[ -z "$ws_edition" ] && ws_edition="(none)"

declare -A seen
for c in crates/*/Cargo.toml; do
    if grep -qE 'edition\.workspace *= *true' "$c"; then
        eff="$ws_edition"
    else
        eff=$(grep -oE '^edition *= *"[^"]+"' "$c" | grep -oE '"[^"]+"' | tr -d '"' | head -1)
        eff="${eff:-$ws_edition}"
    fi
    seen["$eff"]=1
done

n=${#seen[@]}
if [ "$n" -le 1 ]; then
    for k in "${!seen[@]}"; do echo "edition-consistency: ok (edition $k)"; done
else
    echo "FAIL: crates resolve to different editions:"
    for k in "${!seen[@]}"; do echo "  $k"; done
    exit 1
fi
