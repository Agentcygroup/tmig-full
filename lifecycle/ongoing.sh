#!/usr/bin/env bash
set -uo pipefail
ROOT="/Users/metadusa/tmig-full"
LOG="$ROOT/receipts/lifecycle-ongoing.log"
mkdir -p "$(dirname "$LOG")"

ts() { date -u +%FT%TZ; }
up() {
    curl -sf --max-time 3 "http://127.0.0.1:$1/health" >/dev/null 2>&1 || \
    curl -sf --max-time 3 "http://127.0.0.1:$1/v1/models" >/dev/null 2>&1
}

{
    printf '%s == cycle ==\n' "$(ts)"
    dead=()
    for port in 8080 8081 8082 8083 8084; do
        if up "$port"; then
            printf '  ok    :%s\n' "$port"
        else
            printf '  down  :%s\n' "$port"
            dead+=("$port")
        fi
    done

    if [ ${#dead[@]} -gt 0 ]; then
        printf '  restarting via sovereign-host.sh (dead: %s)\n' "${dead[*]}"
        bash "$ROOT/scripts/sovereign-host.sh" >> "$LOG" 2>&1 || true
        printf '  waiting 45s for restart to complete...\n'
        sleep 45
        for port in "${dead[@]}"; do
            if up "$port"; then
                printf '  recovered :%s\n' "$port"
            else
                printf '  still-down :%s\n' "$port"
            fi
        done
    fi
} >> "$LOG" 2>&1
