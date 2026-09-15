#!/usr/bin/env bash
# UK AI Regulation White Paper (2023): five principles. Each must have
# a corresponding check in docs/STANDARDS.md.
set -euo pipefail
cd "$(dirname "$0")/../../.."
for p in safety transparency fairness accountability contestability; do
    grep -qi "$p" docs/STANDARDS.md || { echo "FAIL: UK principle '$p' untraced"; exit 1; }
done
echo "uk-ai-principles: ok"
