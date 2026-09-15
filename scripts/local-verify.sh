#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

run() { printf '\n== %s ==\n' "$*"; "$@"; }

run cargo fmt --all -- --check
run cargo clippy --all-targets --all-features -- -D warnings
run cargo test --release --all-targets
run cargo audit
run cargo deny check
run bash -c 'cargo sbom --output-format spdx_json_2_3 > /dev/null'
run if [ ! -x target/release/xt ]; then
  echo "== building xt =="
  cargo build --release -p xt || exit 1
fi
./target/release/xt policy-check
run bash scripts/repro-check.sh

run bash infra/check.sh

run bash kernel/check.sh

run bash go/check.sh

echo
echo "ALL LOCAL CHECKS PASS"
