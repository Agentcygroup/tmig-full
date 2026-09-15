#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f kernel.cedar ] || { echo "FAIL kernel.cedar"; exit 1; }
[ -f schema.json ]  || { echo "FAIL schema.json";  exit 1; }
[ -x kernel-tests/kernel.py ] || { echo "FAIL kernel.py"; exit 1; }
python3 kernel-tests/kernel.py
echo "kernel ok"
