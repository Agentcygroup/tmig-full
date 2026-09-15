#!/usr/bin/env bash
# Public items should have doc comments. This check reports missing docs
# but does not fail the build while the gap is large — see OPEN.md.
# Tighten by replacing "warn" with "fail" once OPEN.md#docs is empty.
set -euo pipefail
cd "$(dirname "$0")/../.."

missing=$(RUSTDOCFLAGS="-D missing_docs" cargo doc --workspace --no-deps 2>&1 \
          | grep -c "missing documentation" || true)
if [ "$missing" -eq 0 ]; then
    echo "rustdoc: ok (0 missing)"
else
    echo "rustdoc: $missing missing doc items (see OPEN.md#docs)"
fi
