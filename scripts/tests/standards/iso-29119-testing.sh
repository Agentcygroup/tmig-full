#!/usr/bin/env bash
# ISO/IEC/IEEE 29119 software testing: keyword-driven and modular tests.
# Every Rust test file must be a module of assertions (no empty tests).
set -euo pipefail
cd "$(dirname "$0")/../../.."
fail=0
for f in $(find crates -path '*/tests/*.rs' 2>/dev/null); do
    n=$(grep -c '#\[test\]' "$f" || true)
    [ "$n" -gt 0 ] || { echo "FAIL: $f has no #[test]"; fail=1; }
done
[ $fail -eq 0 ] && echo "iso-29119-testing: ok" || exit 1
