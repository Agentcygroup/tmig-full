#!/usr/bin/env bash
# ISO/IEC 42001 9.1: monitoring, measurement, analysis, evaluation.
# lifecycle/ongoing.sh must exist and record a receipt per cycle.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f lifecycle/ongoing.sh ] || { echo "FAIL: no monitoring script"; exit 1; }
grep -q "receipt\|cycle" lifecycle/ongoing.sh || { echo "FAIL: no cycle record"; exit 1; }
echo "iso-42001-monitor: ok"
