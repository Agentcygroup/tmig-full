#!/usr/bin/env bash
# OECD Principle 1.5: systematic risk management approach. OPEN.md must
# list known risks and unimplemented paths.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f OPEN.md ] || { echo "FAIL: OPEN.md missing (risk register)"; exit 1; }
grep -q "Unsupported\|todo\|implemented" OPEN.md || { echo "FAIL: OPEN.md has no risk entries"; exit 1; }
echo "oecd-risk: ok"
