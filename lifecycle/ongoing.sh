#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p receipts
printf '%s == cycle ==\n' "$(date -u +%FT%TZ)" >> receipts/lifecycle-ongoing.log
echo "cycle: ok"
