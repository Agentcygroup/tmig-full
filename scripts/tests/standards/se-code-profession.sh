#!/usr/bin/env bash
# SE Code Principle 6 (PROFESSION): advance integrity and reputation.
# Every invariant must be indexed in docs/INVARIANTS.md.
set -euo pipefail
cd "$(dirname "$0")/../../.."
bash scripts/tests/invariants-indexed.sh && echo "se-code-profession: ok"
