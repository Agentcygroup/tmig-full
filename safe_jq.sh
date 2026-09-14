#!/usr/bin/env bash
set -euo pipefail
# Safe JSON argument wrapper for jq --argjson
safe_argjson() {
    local key="$1"
    local val="${2:-null}"
    # Ensure val is valid JSON, fallback to null or quoted string if not parseable
    if ! echo "$val" | jq empty 2>/dev/null; then
        val=$(jq -n --arg v "$val" '$v')
    fi
    echo "$val"
}
