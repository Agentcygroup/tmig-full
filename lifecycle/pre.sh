#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f Cargo.toml ] || { echo "pre: no Cargo.toml"; exit 1; }
df -k "$PWD" | tail -1 | awk '{ if ($4 < 1048576) { print "pre: <1GB free"; exit 1 } }'
echo "pre ok"
