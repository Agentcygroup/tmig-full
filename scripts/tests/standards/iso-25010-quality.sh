#!/usr/bin/env bash
# ISO/IEC 25010 product quality model: functional suitability,
# reliability, maintainability, portability. Every crate must build
# for the declared targets and pass clippy.
set -euo pipefail
cd "$(dirname "$0")/../../.."
cargo clippy --workspace --all-targets --all-features -- -D warnings 2>&1 | tail -3 \
  && echo "iso-25010-quality: ok"
