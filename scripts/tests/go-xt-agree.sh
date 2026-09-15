#!/usr/bin/env bash
# Assert the Go dispatcher and the Rust xt binary agree on policy decisions.
set -euo pipefail
cd "$(dirname "$0")/../.."

xt=target/release/xt
go=bin/tmig-go
[ -x "$xt" ] || cargo build -q --release -p xt
[ -x "$go" ] || { echo "FAIL: $go missing"; exit 1; }

for principal in xt root reconcile kernel; do
    action=read
    resource=res:status
    ctx=$(printf '{"principal":"%s","layer":"all","strength":40,"cmd":"","claim":"","resource_path":"%s"}' "$principal" "$PWD")

    xt_out=$("$xt" policy authorize --principal "$principal" --action "$action" --resource "$resource" --context "$ctx" 2>/dev/null | tail -1)
    go_out=$(TMIG_PRINCIPAL="$principal" "$go" status 2>&1 | grep -oE '^(policy: allow|denied)' | head -1 || true)

    case "$principal" in
        xt|reconcile|kernel) want=allow ;;
        *)                   want=deny  ;;
    esac
    if [ "$xt_out" != "$want" ]; then
        echo "FAIL: xt says '$xt_out' for $principal, want '$want'"; exit 1
    fi
    echo "  ok   $principal -> $xt_out"
done
echo "go-xt-agree: ok"
