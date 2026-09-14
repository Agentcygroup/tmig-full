#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
source checks/engines.sh

EXPECT="2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
ok=0; fail=0; ran=0
probe() {
  local lang="$1" cmd="$2" out
  out=$(cd "bindings/$lang" && eval "$cmd" 2>/dev/null) || {
    printf '  fail    %-12s (exit)\n' "$lang"; fail=$((fail+1)); return
  }
  if [ "$out" = "$EXPECT" ]; then
    printf '  ok      %-12s %s\n' "$lang" "$out"; ok=$((ok+1))
  else
    printf '  fail    %-12s %s\n' "$lang" "$out"; fail=$((fail+1))
  fi
}
[ -d bindings/python ] && engine_present python && { probe python 'python3 -c "import tmig; print(tmig.id_of(b\"hello\"))"'; ran=$((ran+1)); }
[ -d bindings/ruby   ] && engine_present ruby   && { probe ruby   'ruby -e "require \"$PWD/tmig\"; puts Tmig.id_of(\"hello\")"'; ran=$((ran+1)); }
[ -d bindings/node   ] && engine_present node   && { probe node   'node -e "console.log(require(\"./tmig\").idOf(Buffer.from(\"hello\")))"'; ran=$((ran+1)); }
[ -d bindings/go     ] && engine_present go     && { probe go     'CGO_ENABLED=1 go run ./cmd/tmig'; ran=$((ran+1)); }
printf 'agreement: %d ok, %d fail, %d ran\n' "$ok" "$fail" "$ran"
[ "$fail" -eq 0 ]
