#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
source checks/engines.sh

REQ="checks/lang/engines.required"
[ -f "$REQ" ] || { echo "FAIL: missing $REQ"; exit 1; }

declare -A REQUIRED=()
while IFS= read -r line; do
  line="${line%%#*}"; line="$(echo "$line" | xargs)"
  [ -n "$line" ] && REQUIRED["$line"]=1
done < "$REQ"

present=0; absent=0; missing=0
absent_list=()
for name in "${!ENGINES[@]}"; do
  if engine_present "$name"; then
    present=$((present+1))
  else
    absent=$((absent+1)); absent_list+=("$name")
    if [ -n "${REQUIRED[$name]:-}" ]; then
      printf '  MISSING (required)  %-16s %s\n' "$name" "${ENGINES[$name]}"
      missing=$((missing+1))
    fi
  fi
done
for name in "${!REQUIRED[@]}"; do
  if [ -z "${ENGINES[$name]:-}" ]; then
    printf '  MISSING (unknown)   %-16s (not in ENGINES)\n' "$name"
    missing=$((missing+1))
  fi
done

printf 'engines: %d present, %d absent, %d required\n' "$present" "$absent" "${#REQUIRED[@]}"
[ "$missing" -eq 0 ] || { echo "FAIL: $missing required engine(s) missing"; printf 'absent: %s\n' "${absent_list[*]}"; exit 1; }
exit 0
