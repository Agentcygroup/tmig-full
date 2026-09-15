#!/usr/bin/env bash
# Prove xt release is reproducible: two clean checkouts, compare bytes.
set -euo pipefail
REPO="${1:-$HOME/tmig-full}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for d in a b; do
    git -C "$REPO" worktree add -q "$WORK/$d" HEAD
    ( cd "$WORK/$d"
      cargo build --release --locked -p xt -p release >/dev/null 2>&1
      cargo run --release --locked -p release --bin xt-release -- \
          --repo "$PWD" --out "$WORK/$d/out" >/dev/null
    )
done

A="$(ls "$WORK/a/out/"*.tar.gz | head -1)"
B="$(ls "$WORK/b/out/"*.tar.gz | head -1)"

if cmp -s "$A" "$B"; then
    echo "REPRODUCIBLE: $(basename "$A")"
    exit 0
fi

echo "NOT REPRODUCIBLE"
echo "  a: $(shasum -a 256 "$A" | awk '{print $1}')"
echo "  b: $(shasum -a 256 "$B" | awk '{print $1}')"
if command -v diffoscope >/dev/null 2>&1; then
    diffoscope --text - "$A" "$B" | head -50
fi
exit 1
