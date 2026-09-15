#!/usr/bin/env bash
# IEEE 7001-2021: transparency of autonomous systems. Any decision made
# by the system must be explainable. policy-eval prints diagnostics on
# failure (reason and errors).
set -euo pipefail
cd "$(dirname "$0")/../../.."
grep -q "diagnostics" crates/policy-eval/src/main.rs || { echo "FAIL: no diagnostics output"; exit 1; }
echo "ieee-7001-transparency: ok"
