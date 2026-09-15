#!/usr/bin/env bash
# Every crate that depends on a shared crate must not define a struct with
# the same name as one exported by that crate.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
# Names that are known different concepts; do not flag.
ALLOW="schema:NonClaimRecord"
# check each shared crate's public type names against every dependent crate
for shared in nonclaim seam; do
    exports=$(grep -hoE 'pub (struct|enum) [A-Z][A-Za-z]+' crates/$shared/src/*.rs 2>/dev/null \
              | awk '{print $3}' | sort -u || true)
    [ -z "$exports" ] && continue
    for other in $(ls crates); do
        [ "$other" = "$shared" ] && continue
        [ -d "crates/$other/src" ] || continue
        for t in $exports; do
            if grep -rqE "pub (struct|enum) $t\b" crates/$other/src 2>/dev/null; then
                echo "FAIL: crates/$other redefines $t (exported by $shared)"
                fail=1
            fi
        done
    done
done
[ $fail -eq 0 ] && echo "no-duplicate-types: ok" || exit 1
