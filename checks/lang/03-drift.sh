#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/../.."
source checks/engines.sh

RECEIPT="checks/lang/engines.present"
current="$(for name in "${!ENGINES[@]}"; do engine_present "$name" && echo "$name"; done | sort || true)"

if [ ! -f "$RECEIPT" ]; then
  printf '%s\n' "$current" > "$RECEIPT"
  echo "drift: baseline written ($(printf '%s\n' "$current" | wc -l | xargs) engines)"
  exit 0
fi
if diff <(printf '%s\n' "$current") "$RECEIPT" > /tmp/drift.$$ 2>&1; then
  echo "drift: none"
else
  echo "drift: present set changed"
  sed 's/^/  /' /tmp/drift.$$
  printf '%s\n' "$current" > "$RECEIPT"
fi
rm -f /tmp/drift.$$
exit 0
