#!/usr/bin/env bash
# NIST AI RMF GOVERN 1.1: legal and regulatory requirements are
# understood, managed, and documented. docs/STANDARDS.md is the register.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f docs/STANDARDS.md ] || { echo "FAIL: no regulatory register"; exit 1; }
n=$(grep -c '^|' docs/STANDARDS.md)
[ "$n" -gt 3 ] || { echo "FAIL: register has too few entries"; exit 1; }
echo "nist-govern: ok ($n entries)"
