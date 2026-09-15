#!/usr/bin/env bash
# Every scripts/tests/*.sh must appear in docs/INVARIANTS.md, and every
# `crates/**/tests/*.rs` test file must too.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
for f in scripts/tests/*.sh; do
    name=$(basename "$f")
    [ "$name" = "invariants-indexed.sh" ] && continue
    if ! grep -q "$name" docs/INVARIANTS.md; then
        echo "FAIL: $name not indexed in docs/INVARIANTS.md"
        fail=1
    fi
done
for f in $(find crates -path '*/tests/*.rs' -type f 2>/dev/null); do
    base=$(basename "$f")
    if ! grep -q "$base" docs/INVARIANTS.md; then
        echo "FAIL: $base not indexed in docs/INVARIANTS.md"
        fail=1
    fi
done
[ $fail -eq 0 ] && echo "invariants-indexed: ok" || exit 1
