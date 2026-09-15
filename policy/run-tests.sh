#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Concatenate every policy source into one document.
POLICY=$(cat schema.cedar.json principals.cedar actions.cedar resources.cedar rules/*.cedar)

# Use cedar's CLI if present, else fall back to the kernel Rust evaluator.
if command -v cedar >/dev/null 2>&1; then
    cedar_bin=cedar
elif [ -x ../target/release/cedar-cli ]; then
    cedar_bin=../target/release/cedar-cli
else
    # Fall back to the kernel's own evaluator via a Rust test.
    echo "  note: cedar CLI not installed; using kernel evaluator"
    cargo run --release -q -p kernel --example eval-policy -- "$(pwd)" || {
        echo "FAIL: no evaluator available"
        exit 1
    }
    exit 0
fi

# cedar CLI path
pass=0; fail=0
while IFS= read -r row; do
    id=$(jq -r '.id' <<<"$row")
    principal=$(jq -r '.principal' <<<"$row")
    action=$(jq -r '.action' <<<"$row")
    resource=$(jq -r '.resource' <<<"$row")
    rpath=$(jq -r '.resource_path' <<<"$row")
    ctx=$(jq -c '.context' <<<"$row")
    expect=$(jq -r '.expect' <<<"$row")

    got=$("$cedar_bin" authorize \
        --policies <(echo "$POLICY") \
        --principal "Principal::\"$principal\"" \
        --action "Action::\"$action\"" \
        --resource "Resource::\"$resource\"" \
        --context "$ctx" 2>/dev/null || echo "error")

    if [ "$got" = "$expect" ]; then
        printf '  ok    %-32s %s\n' "$id" "$got"; pass=$((pass+1))
    else
        printf '  FAIL  %-32s got=%s want=%s\n' "$id" "$got" "$expect"; fail=$((fail+1))
    fi
done < <(jq -c '.rows[]' tests/decision-table.json)

echo "  $pass passed, $fail failed"
[ $fail -eq 0 ]
