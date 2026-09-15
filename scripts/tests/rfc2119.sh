#!/usr/bin/env bash
# RFC 2119 defines the requirement levels every standards body uses.
# Every derivation in docs/STANDARDS.md must state its level, and the
# artifact's own claims must use the same vocabulary.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
grep -qE '\b(MUST|SHOULD|MAY)\b' docs/STANDARDS.md || {
    echo "FAIL: docs/STANDARDS.md has no RFC 2119 language"; fail=1; }
grep -qE '\b(MUST|SHOULD|MAY)\b' docs/INDUSTRIES.md || {
    echo "FAIL: docs/INDUSTRIES.md has no RFC 2119 language"; fail=1; }
grep -qE '\b(MUST|SHOULD|MAY)\b' docs/INVARIANTS.md || {
    echo "FAIL: docs/INVARIANTS.md has no RFC 2119 language"; fail=1; }

[ $fail -eq 0 ] && echo "rfc2119: ok" || exit 1
