#!/usr/bin/env bash
# IEEE 7000-2021: traceability of ethical values in concept of operations
# and ethical requirements. docs/STANDARDS.md is the value trace.
set -euo pipefail
cd "$(dirname "$0")/../../.."
grep -q "OECD\|UNESCO\|CoE\|NIST\|IEEE" docs/STANDARDS.md || { echo "FAIL: no values traced"; exit 1; }
echo "ieee-7000-values: ok"
