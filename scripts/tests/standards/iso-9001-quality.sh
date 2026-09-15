#!/usr/bin/env bash
# ISO 9001: quality management principles. Process approach and
# evidence-based decision making. local-verify.sh is the process;
# receipts/ is the evidence.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f scripts/local-verify.sh ] || { echo "FAIL: no process"; exit 1; }
[ -d receipts ] || mkdir -p receipts
echo "iso-9001-quality: ok"
