#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -x cli/tmig ]               || { echo "FAIL cli/tmig"; exit 1; }
[ -f web/server.py ]          || { echo "FAIL server.py"; exit 1; }
[ -f web/static/index.html ]  || { echo "FAIL index.html"; exit 1; }
bash -n cli/tmig
python3 -c "import ast; ast.parse(open('web/server.py').read())"
echo "ui ok"
