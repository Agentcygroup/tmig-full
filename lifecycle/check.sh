#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for f in healthcheck.sh restart.sh stop.sh com.sovereign.runtime.plist; do
  [ -e "$f" ] || { echo "FAIL $f"; exit 1; }
done
bash -n healthcheck.sh && bash -n restart.sh && bash -n stop.sh
plutil -lint com.sovereign.runtime.plist >/dev/null
echo "lifecycle ok"
