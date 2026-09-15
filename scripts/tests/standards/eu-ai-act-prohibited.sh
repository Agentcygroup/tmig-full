#!/usr/bin/env bash
# EU AI Act Art. 5: prohibited practices. Social scoring, subliminal
# manipulation, and emotion recognition in workplaces are forbidden.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -f policy/rules/12-eu-ai-act.cedar ] || { echo "FAIL: EU rule missing"; exit 1; }
grep -q "social_score" policy/rules/12-eu-ai-act.cedar || { echo "FAIL: no social scoring ban"; exit 1; }
grep -q "social_scoring" policy/tests/decision-table.json || { echo "FAIL: no test row"; exit 1; }
echo "eu-ai-act-prohibited: ok"
