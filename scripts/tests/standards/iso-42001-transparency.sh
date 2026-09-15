#!/usr/bin/env bash
# ISO/IEC 42001 A.7: transparency to users. Every harness carries a
# nonclaim and cites its instrument.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -d harnesses ] || { echo "iso-42001-transparency: no harnesses; skip"; exit 0; }
fail=0
for h in harnesses/*.harness; do
    grep -q "nonclaim" "$h" || { echo "FAIL: $h no nonclaim"; fail=1; }
    grep -q "cite" "$h" || { echo "FAIL: $h no cite"; fail=1; }
done
[ $fail -eq 0 ] && echo "iso-42001-transparency: ok" || exit 1
