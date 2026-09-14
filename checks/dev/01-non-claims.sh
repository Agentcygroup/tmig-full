#!/usr/bin/env bash
set -euo pipefail; cd "$(dirname "$0")/../.."
[ -f docs/NON_CLAIMS.md ] || { echo "missing"; exit 1; }
for n in no-mastery no-accreditation no-coherence-proof no-completeness; do
  grep -q "$n" docs/NON_CLAIMS.md || { echo "missing $n"; exit 1; }
done
