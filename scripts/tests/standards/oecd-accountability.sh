#!/usr/bin/env bash
# OECD/LEGAL/0449 Principle 1.5: traceability of decisions made during the
# AI system lifecycle. Every op that produces a receipt must name an
# accountable principal. Mirrors policy/rules/10-oecd-ai-principles.cedar.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f policy/rules/10-oecd-ai-principles.cedar ] || { echo "FAIL: OECD rule missing"; exit 1; }
grep -q "accountable" policy/rules/10-oecd-ai-principles.cedar || { echo "FAIL: no accountable principal"; exit 1; }
grep -q "produce_receipt" policy/rules/10-oecd-ai-principles.cedar || { echo "FAIL: no receipt rule"; exit 1; }
echo "oecd-accountability: ok"
