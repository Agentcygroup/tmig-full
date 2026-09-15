#!/usr/bin/env bash
# ISO/IEC 27001 Annex A.8: technological controls. No secrets in source.
set -euo pipefail
cd "$(dirname "$0")/../../.."
fail=0
if grep -rniE 'password|secret|api[_-]?key|token' crates --include='*.rs' 2>/dev/null | grep -v 'test\|//\|pub fn' | head -3; then
    echo "FAIL: possible secret in source"
    fail=1
fi
[ $fail -eq 0 ] && echo "iso-27001-security: ok" || exit 1
