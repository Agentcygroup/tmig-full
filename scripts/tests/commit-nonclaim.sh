#!/usr/bin/env bash
# Commit messages must not claim mastery, accreditation, coherence-proof,
# or completeness. Mirrors nonclaim::FORBIDDEN_CLAIMS.
set -euo pipefail
cd "$(dirname "$0")/../.."

WORDS=(mastery accreditation coherence-proof completeness)
msg=$(git log -1 --format=%B)
fail=0
for w in "${WORDS[@]}"; do
    if grep -qi "$w" <<<"$msg"; then
        echo "FAIL: HEAD commit message contains forbidden claim: $w"
        fail=1
    fi
done
if [ $fail -eq 0 ]; then echo "commit-nonclaim: ok"; else exit 1; fi
