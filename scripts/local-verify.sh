#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== cargo fmt --all -- --check =="
cargo fmt --all -- --check

echo
echo "== cargo clippy --all-targets --all-features -- -D warnings =="
cargo clippy --all-targets --all-features -- -D warnings

echo
echo "== cargo test --release --all-targets =="
cargo test --release --all-targets

echo
echo "== cargo audit =="
cargo audit

echo
echo "== cargo deny check =="
cargo deny check

echo
echo "== cargo sbom =="
bash -c 'cargo sbom --output-format spdx_json_2_3 > /dev/null'

echo
echo "== xt policy-check =="
if [ ! -x target/release/xt ]; then
  echo "  building xt"
  cargo build --release -p xt
fi
./target/release/xt policy-check
