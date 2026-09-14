#!/usr/bin/env bash
# tmig-full automation — does everything not already scripted
# usage:
#   ./automate.sh jupyter-fix         pin httpx+tornado in every venv that has jupyterlab
#   ./automate.sh tools               install the 7 cloned tools into their own venvs
#   ./automate.sh commit              stage tracked-only + commit + push
#   ./automate.sh status              one-line health check of the whole tree
#   ./automate.sh all                 run jupyter-fix + tools + commit + status
set -euo pipefail

ROOT="$HOME/tmig-full"
VENVS="$ROOT/venvs"
GVENVS="$ROOT/venvs-graph"
REQS="$ROOT/requirements.d"
TOOLS="$ROOT/tools"
TOOL_VENVS="$ROOT/tool-venvs"
REC_REQ="$ROOT/receipts/reqs"
LOG="$ROOT/receipts/automate.log"
mkdir -p "$REC_REQ" "$TOOL_VENVS" "$(dirname "$LOG")"

log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }

fix_jupyter() {
  log "== jupyter-fix =="
  local count=0
  for v in "$VENVS"/*/ "$GVENVS"/*/; do
    [ -x "$v/bin/jupyter" ] || continue
    [ -x "$v/bin/python" ] || continue
    local name; name="$(basename "$v")"
    log "  $name: pinning httpx<0.28 tornado<6.5"
    "$v/bin/python" -m pip install -q "httpx<0.28" "tornado<6.5" 2>>"$LOG" || {
      log "    FAIL: $name"
      continue
    }
    case "$v" in
      "$VENVS"/*) "$v/bin/python" -m pip freeze > "$REC_REQ/$name.freeze" ;;
    esac
    count=$((count+1))
  done
  log "  fixed $count venv(s)"
}

install_tools() {
  log "== tools =="
  mkdir -p "$ROOT/receipts/tools"
  local ts
  ts=$(date +%s)
  local specs=(
    "setoolkit    $TOOLS/setoolkit"
    "xsser        $TOOLS/xsser"
    "xsstrike     $TOOLS/xsstrike"
    "dnschef      $TOOLS/dnschef"
    "wifite2      $TOOLS/wifite2"
    "evilginx2    $TOOLS/evilginx2"
    "cuckoo       $TOOLS/cuckoo"
    "cve-search   $TOOLS/cve-search"
  )
  for entry in "${specs[@]}"; do
    local name src
    name="$(echo "$entry" | awk '{print $1}')"
    src="$(echo "$entry" | awk '{print $2}')"
    if [ ! -d "$src" ]; then
      log "  $name: source missing ($src)"
      continue
    fi
    local venv="$TOOL_VENVS/$name"
    if [ ! -x "$venv/bin/python" ]; then
      log "  $name: creating venv"
      python3 -m venv "$venv" 2>>"$LOG"
      "$venv/bin/python" -m pip install --upgrade pip -q 2>>"$LOG"
    fi

    # each tool has its own install convention
    case "$name" in
      setoolkit)
        "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
      xsser)
        [ -f "$src/setup.py" ] && "$venv/bin/python" -m pip install -q -e "$src" 2>>"$LOG" || true
        ;;
      xsstrike)
        "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
      dnschef)
        "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
      wifite2)
        "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
      evilginx2)
        if command -v go >/dev/null 2>&1; then
          (cd "$src" && go build -o "$venv/bin/evilginx2" . 2>>"$LOG") || log "    go build failed"
        else
          log "    no go toolchain — skipping build"
        fi
        ;;
      cuckoo)
        "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
      cve-search)
        [ -f "$src/requirements.txt" ] && \
          "$venv/bin/python" -m pip install -q -r "$src/requirements.txt" 2>>"$LOG" || true
        ;;
    esac

    mkdir -p "$ROOT/receipts/tools"
    "$venv/bin/python" -m pip freeze > "$ROOT/receipts/tools/$name.freeze" 2>/dev/null || true
    log "  $name: installed ($(wc -l < "$ROOT/receipts/tools/$name.freeze") pkgs)"
  done
  log "  tools ready under $TOOL_VENVS"
}

commit() {
  log "== commit =="
  cd "$ROOT"
  # ensure .gitignore is comprehensive
  cat > .gitignore <<'EOF'
# Rust
target/

# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv*/
venvs/
venvs-graph/
venv-*/
tool-venvs/

# build / cache
.stacks/
receipts/reqs-logs/
receipts/automate.log

# cloned external repos
tools/

# OS
.DS_Store
EOF

  git add .gitignore
  git add receipts/requirements.d requirements.oss.txt resplit.sh venv.sh automate.sh 2>/dev/null || true
  git add receipts/reqs receipts/graph receipts/freeze receipts/tools 2>/dev/null || true
  git add xt.toml docs/ 2>/dev/null || true

  if git diff --cached --quiet; then
    log "  nothing to commit"
  else
    git -c user.email=b@x -c user.name=b commit -q -m "automate: venv.sh + automate.sh, httpx/tornado pins, tool receipts"
    log "  committed $(git rev-parse --short HEAD)"
  fi

  git status -sb | head -1 | tee -a "$LOG"

  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push origin HEAD 2>>"$LOG" && log "  pushed" || log "  push failed (see log)"
  else
    log "  no upstream — skipping push"
  fi
}

status() {
  log "== status =="
  local t v g tv
  t=$(cd "$ROOT" && git ls-files | wc -l | tr -d ' ')
  v=$(ls -1 "$VENVS" 2>/dev/null | wc -l | tr -d ' ')
  g=$(ls -1 "$GVENVS" 2>/dev/null | wc -l | tr -d ' ')
  tv=$(ls -1 "$TOOL_VENVS" 2>/dev/null | wc -l | tr -d ' ')
  log "  tracked files:  $t"
  log "  req venvs:      $v"
  log "  graph venvs:    $g"
  log "  tool venvs:     $tv"
  log "  xt ci:"
  "$ROOT/target/release/xt" ci 2>&1 | grep -E '^\s+(ok|cached|fail)' | sed 's/^/    /' | tee -a "$LOG" || true
}

case "${1:-}" in
  jupyter-fix)  fix_jupyter ;;
  tools)        install_tools ;;
  commit)       commit ;;
  status)       status ;;
  all)          fix_jupyter; install_tools; commit; status ;;
  "")           sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)            echo "unknown: $1" >&2; exit 1 ;;
esac
