#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
LOG="$HOME/tmig-full/receipts/lifecycle-ongoing.log"
mkdir -p "$(dirname "$LOG")"
if ! bash lifecycle/healthcheck.sh >>"$LOG" 2>&1; then
    bash lifecycle/restart.sh 8081 >>"$LOG" 2>&1 || true
    bash lifecycle/restart.sh 8083 >>"$LOG" 2>&1 || true
fi
printf '%s cycle\n' "$(date -u +%FT%TZ)" >>"$LOG"
