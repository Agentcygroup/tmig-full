#!/usr/bin/env bash
# Every Action::"<x>" in policy/actions.cedar MUST have exactly one
# def Action "<x>" prim in spec/actions/actions.usda, and vice versa.
set -euo pipefail
cd "$(dirname "$0")/../.."

cedar=$(grep -oE 'Action::"[a-z]+"' policy/actions.cedar | sed 's/Action::"//;s/"//' | sort -u)
usd=$(grep -oE '^ *def Action "[a-z]+"' spec/actions/actions.usda | sed 's/.*"\(.*\)"/\1/' | sort -u)

if [ "$cedar" != "$usd" ]; then
    echo "FAIL: Cedar actions and USD action prims diverge"
    diff <(echo "$cedar") <(echo "$usd") || true
    exit 1
fi
echo "usd-actions-covered: ok ($(echo "$cedar" | wc -l | tr -d ' ') actions)"
