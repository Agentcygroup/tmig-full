#!/usr/bin/env bash
# BCS Code: do not claim any level of competence you do not possess.
# The nonclaim rule forbids "mastery" and "accreditation".
set -euo pipefail
cd "$(dirname "$0")/../../.."
grep -q "mastery" policy/rules/04-nonclaims.cedar || { echo "FAIL: no mastery ban"; exit 1; }
grep -q "accreditation" policy/rules/04-nonclaims.cedar || { echo "FAIL: no accreditation ban"; exit 1; }
echo "bcs-competence: ok"
