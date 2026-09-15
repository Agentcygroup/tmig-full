#!/usr/bin/env bash
# SE Code Principle 3 (PRODUCT): highest professional standards.
# Clippy with -D warnings is the floor.
set -euo pipefail
cd "$(dirname "$0")/../../.."
cargo clippy --workspace --all-targets --all-features -- -D warnings 2>&1 | tail -2 \
  && echo "se-code-product: ok"
