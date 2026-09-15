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

# --- sdcl: every harness emits for every SDLC phase ---
echo "== sdcl-check =="
make sdcl-check

# --- go-xt agreement: the Go dispatcher and xt must agree on policy ---
echo "== go-xt-agree =="
bash scripts/tests/go-xt-agree.sh

# --- invariant checks ---
for t in commit-nonclaim nonclaim-type-identity locked-build \
         hooks-installed resource-bounds docs-claims open-tracking \
         time-bounds cross-target; do
    echo "== $t =="
    bash scripts/tests/$t.sh || { echo "FAIL: $t"; exit 1; }
done

for t in concurrency invariants-indexed no-duplicate-types \
         version-consistency rustdoc cli-contracts schema-presence \
         coverage-by-name edition-consistency no-absolute-paths \
         makefile-docs; do
    echo "== $t =="
    bash scripts/tests/$t.sh || { echo "FAIL: $t"; exit 1; }
done

echo
echo "ALL LOCAL CHECKS PASS"
