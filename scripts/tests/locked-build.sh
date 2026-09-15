#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
cargo build --locked -q 2>&1 | tail -5 && echo "locked-build: ok"
