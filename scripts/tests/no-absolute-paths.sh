#!/usr/bin/env bash
# Source under crates/ must not contain /Users/... or /home/... — those
# belong in fixtures, not in code.
set -euo pipefail
cd "$(dirname "$0")/../.."
fail=0
if grep -rn '/Users/\|/home/' crates --include='*.rs' 2>/dev/null | grep -v 'tests/'; then
    echo "FAIL: absolute path in source (see above)"
    fail=1
fi
[ $fail -eq 0 ] && echo "no-absolute-paths: ok" || exit 1
