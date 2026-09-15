#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -x release.sh ] || { echo "FAIL release.sh"; exit 1; }
[ -x ../scripts/local-verify.sh ] || { echo "FAIL local-verify.sh"; exit 1; }
bash -n release.sh
echo "ci ok"
