#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -c "import yaml; yaml.safe_load(open('ops.yaml')); yaml.safe_load(open('entities.yaml'))"
echo "  ok   hybrids"
