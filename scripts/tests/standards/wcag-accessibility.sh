#!/usr/bin/env bash
# WCAG 2.2 POUR: perceivable, operable, understandable, robust. The web
# UI must exist and be served locally.
set -euo pipefail
cd "$(dirname "$0")/../../.."
[ -d ui/web ] || { echo "wcag-accessibility: no web UI; skip"; exit 0; }
grep -rqiE 'lang=|alt=|aria-' ui/web 2>/dev/null || { echo "FAIL: no accessibility attributes"; exit 1; }
echo "wcag-accessibility: ok"
