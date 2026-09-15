#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

want=scripts/githooks
have=$(git config core.hooksPath || true)
if [ "$have" != "$want" ]; then
    echo "FAIL: core.hooksPath is '$have', want '$want'"
    exit 1
fi
[ -x scripts/githooks/pre-push ] || { echo "FAIL: pre-push not executable"; exit 1; }
echo "hooks-installed: ok"
