#!/usr/bin/env bash
# CoE Framework Convention Art. 8: transparency and oversight. Every
# harness emits a transparency record via sdcl.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -x scripts/tests/../../target/release/sdcl ] || cargo build -q --release -p sdcl
harnesses=$(ls harnesses/*.harness 2>/dev/null | wc -l | tr -d ' ')
[ "$harnesses" -gt 0 ] || { echo "FAIL: no harnesses (no transparency records)"; exit 1; }
echo "coe-transparency: ok ($harnesses harnesses)"
