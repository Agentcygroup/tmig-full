#!/usr/bin/env bash
# Build for every target listed in rust-toolchain.toml. Skips targets that
# rustup has not installed, so the check is honest about what it covers.
set -euo pipefail
cd "$(dirname "$0")/../.."

if [ ! -f rust-toolchain.toml ]; then echo "cross-target: no rust-toolchain.toml; skip"; exit 0; fi
targets=$(grep -oE '"[^"]+"' rust-toolchain.toml | tr -d '"' | grep -E 'apple|linux|windows' || true)
[ -n "$targets" ] || { echo "cross-target: no targets listed; skip"; exit 0; }
for t in $targets; do
    if rustup target list --installed 2>/dev/null | grep -q "^$t$"; then
        echo "  build --target $t"
        cargo build --locked --target "$t" -q 2>&1 | tail -3 || { echo "FAIL: $t"; exit 1; }
    else
        echo "  skip $t (not installed)"
    fi
done
echo "cross-target: ok"
