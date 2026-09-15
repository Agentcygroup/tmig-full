#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -x scaffold.sh ] || { echo "FAIL scaffold.sh"; exit 1; }
[ -x doctor.sh ]   || { echo "FAIL doctor.sh"; exit 1; }
bash -n scaffold.sh && bash -n doctor.sh
echo "dxp ok"
