#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f LICENSE ] || { echo "FAIL LICENSE missing"; exit 1; }
grep -q 'BSD 3-Clause' LICENSE || { echo "FAIL not BSD-3"; exit 1; }
[ -f licensing/licenses.d/allow.yaml ] || { echo "FAIL allow.yaml"; exit 1; }
echo "licensing ok"
