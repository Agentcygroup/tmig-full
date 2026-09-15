#!/usr/bin/env bash
# UNESCO Recommendation (2021): Ethical Impact Assessment (EIA) is a core
# tool. An EIA record must exist in docs/.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f docs/STANDARDS.md ] || { echo "FAIL: no standards derivation doc"; exit 1; }
grep -qi "impact assessment" docs/STANDARDS.md || { echo "FAIL: no EIA reference"; exit 1; }
echo "unesco-eia: ok"
