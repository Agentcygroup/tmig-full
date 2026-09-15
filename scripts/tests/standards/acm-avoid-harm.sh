#!/usr/bin/env bash
# ACM Code 1.2: avoid harm. No destructive commands in source.
set -euo pipefail
cd "$(dirname "$0")/../../.."
fail=0
if grep -rnE 'rm -rf /|dd if=|:\(\)\{' crates scripts --include='*.rs' --include='*.sh' 2>/dev/null | grep -v 'test\|//' | head -3; then
    echo "FAIL: destructive pattern in source"
    fail=1
fi
[ $fail -eq 0 ] && echo "acm-avoid-harm: ok" || exit 1
