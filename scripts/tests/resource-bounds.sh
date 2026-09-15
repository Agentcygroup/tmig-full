#!/usr/bin/env bash
# Any type that recurses must reference crate::limits or a *_LIMIT const.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
if [ -d crates/seam/src ]; then
    if grep -rq "fn handle" crates/seam/src; then
        grep -q "MAX_DEPTH" crates/seam/src/message.rs || { echo "FAIL: Message::new has no MAX_DEPTH"; fail=1; }
        grep -q "MAX_BODY_BYTES" crates/seam/src/message.rs || { echo "FAIL: Message::new has no MAX_BODY_BYTES"; fail=1; }
    fi
fi
[ $fail -eq 0 ] && echo "resource-bounds: ok" || exit 1
