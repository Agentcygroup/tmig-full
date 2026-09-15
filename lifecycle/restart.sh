#!/usr/bin/env bash
set -euo pipefail
port="${1:?usage: restart.sh <port>}"
pid=$(lsof -ti:"$port" 2>/dev/null || true)
[ -n "$pid" ] && { kill "$pid" 2>/dev/null || true; sleep 1; }
bash "$HOME/sovereign-host.sh" 2>&1 | grep -E ":$port" || true
