#!/usr/bin/env bash
# Every ISIC section A–U appears; the artifact declares exactly two as
# addressed. The check fails if any row is missing or if the "primary"
# sector (J) is not marked MUST.
set -euo pipefail
cd "$(dirname "$0")/../.."

[ -f docs/INDUSTRIES.md ] || { echo "FAIL: docs/INDUSTRIES.md missing"; exit 1; }

fail=0
for s in A B C D E F G H I J K L M N O P Q R S T U; do
    grep -qE "^\| $s \|" docs/INDUSTRIES.md || { echo "FAIL: ISIC $s missing"; fail=1; }
done
grep -qE '^\| J \|.*\*\*primary' docs/INDUSTRIES.md || {
    echo "FAIL: sector J not marked primary"; fail=1; }
count=$(grep -cE "^\| [A-U] \|.*not addressed" docs/INDUSTRIES.md)
[ "$count" -eq 19 ] || { echo "FAIL: expected 19 'not addressed', got $count"; fail=1; }

[ $fail -eq 0 ] && echo "industries-covered: ok" || exit 1
