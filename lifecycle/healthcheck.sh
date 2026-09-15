#!/usr/bin/env bash
set -uo pipefail
LOG="${HOME}/tmig-full/receipts/lifecycle-health.log"
mkdir -p "$(dirname "$LOG")"
fail=0
{
  printf '%s == healthcheck ==\n' "$(date -u +%FT%TZ)"
  for e in "8080 /v1/models" "8081 /health" "8082 /health" "8083 /health" "8084 /health"; do
    read -r port path <<<"$e"
    curl -sf --max-time 3 "http://127.0.0.1:${port}${path}" >/dev/null 2>&1 \
      && printf '  ok    :%s\n' "$port" \
      || { printf '  down  :%s\n' "$port"; fail=1; }
  done
} | tee -a "$LOG"
exit $fail
