#!/usr/bin/env bash
# ACM Code 1.3: be honest and trustworthy. Commit messages must not
# overclaim; the nonclaim rule already enforces this.
set -euo pipefail
cd "$(dirname "$0")/../../.."
bash scripts/tests/commit-nonclaim.sh && echo "acm-honesty: ok"
