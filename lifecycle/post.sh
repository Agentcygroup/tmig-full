#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash lifecycle/healthcheck.sh
echo "post ok"
