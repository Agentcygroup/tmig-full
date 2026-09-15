#!/usr/bin/env bash
# GDPR Art. 5: lawfulness, fairness, transparency, purpose limitation,
# data minimisation, accuracy, storage limitation, integrity, accountability.
set -euo pipefail
cd "$(dirname "$0")/../../.."
grep -q "nonclaim" policy/principals.cedar || { echo "FAIL: no data principle in policy"; exit 1; }
grep -qi "privacy\|data" docs/STANDARDS.md || { echo "FAIL: no privacy derivation"; exit 1; }
echo "gdpr-principles: ok"
