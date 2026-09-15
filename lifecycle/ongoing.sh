#!/usr/bin/env bash
set -uo pipefail
ROOT="/Users/metadusa/tmig-full"
LOG="$ROOT/receipts/lifecycle-ongoing.log"
mkdir -p "$(dirname "$LOG")"

ts() { date -u +%FT%TZ; }

{
  printf '%s == cycle ==\n' "$(ts)"
  for port in 8080 8081 8082 8083 8084; do
    if curl -sf --max-time 3 "http://127.0.0.1:${port}/health" >/dev/null 2>&1 \
    || curl -sf --max-time 3 "http://127.0.0.1:${port}/v1/models" >/dev/null 2>&1; then
      printf '  ok    :%s\n' "$port"
    else
      printf '  down  :%s — restarting\n' "$port"
      bash "$ROOT/scripts/sovereign-host.sh" >/dev/null 2>&1 || true
      sleep 2
    fi
  done
} >> "$LOG" 2>&1
