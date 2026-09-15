#!/usr/bin/env bash
# harness-lang, seam, and (in future) any other crate must re-export
# nonclaim::NonClaim rather than defining their own.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
for crate in harness-lang seam; do
    src=crates/$crate/src
    if grep -rn "pub struct NonClaim\b\|pub struct NonEmpty\b" "$src" 2>/dev/null | grep -v "pub use"; then
        echo "FAIL: $crate defines its own NonClaim/NonEmpty"
        fail=1
    fi
    if ! grep -rq "nonclaim" "crates/$crate/Cargo.toml"; then
        echo "FAIL: $crate does not depend on nonclaim"
        fail=1
    fi
done
[ $fail -eq 0 ] && echo "nonclaim-type-identity: ok" || exit 1
