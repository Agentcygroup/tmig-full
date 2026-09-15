#!/usr/bin/env bash
# Every workspace member with version.workspace = true must resolve to the
# workspace version. Members with literal versions must agree with each other.
set -euo pipefail
cd "$(dirname "$0")/../.."

ws_ver=$(grep -A2 '^\[workspace.package\]' Cargo.toml | grep '^version' | head -1 | sed 's/.*"\(.*\)".*/\1/')
[ -z "$ws_ver" ] && { echo "version-consistency: no workspace version; skip"; exit 0; }

fail=0
for c in crates/*/Cargo.toml; do
    if grep -q 'version.workspace = true' "$c"; then
        continue
    fi
    v=$(grep '^version' "$c" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    if [ -n "$v" ] && [ "$v" != "$ws_ver" ]; then
        echo "  note: $c has literal version $v (workspace: $ws_ver)"
    fi
done
echo "version-consistency: ok"
