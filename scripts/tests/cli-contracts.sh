#!/usr/bin/env bash
# Every CLI's output format is pinned by an example. If the format changes,
# the golden file fails and the change is intentional.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p tests/golden

# xt policy authorize
cargo build -q -p xt
out=$(target/debug/xt policy authorize \
      --principal xt --action read --resource res:status \
      --context '{"principal":"xt","layer":"all","strength":40,"cmd":"","claim":"","resource_path":"/Users/metadusa/tmig-full"}' \
      2>/dev/null | tail -1)
g="tests/golden/xt-policy-authorize-allow.txt"
[ -f "$g" ] || echo "allow" > "$g"
if [ "$out" != "$(cat "$g")" ]; then
    echo "FAIL: xt policy authorize output drifted (got '$out')"
    exit 1
fi

# sdcl phases
out=$(cargo run -q -p sdcl -- phases | tr '\n' ' ')
g="tests/golden/sdcl-phases.txt"
[ -f "$g" ] || echo "plan design build test release deploy operate maintain retire " > "$g"
if [ "$out" != "$(cat "$g")" ]; then
    echo "FAIL: sdcl phases output drifted"
    exit 1
fi

echo "cli-contracts: ok"
