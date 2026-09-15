#!/usr/bin/env bash
# IEEE 7002-2022: data privacy process. No source file may contain a
# hardcoded personal identifier.
set -euo pipefail
cd "$(dirname "$0")/../../.."
fail=0
if grep -rniE 'email|ssn|social.security|passport' crates --include='*.rs' 2>/dev/null | grep -v 'test\|//' | head -3; then
    echo "FAIL: possible PII in source"
    fail=1
fi
[ $fail -eq 0 ] && echo "ieee-7002-privacy: ok" || exit 1
