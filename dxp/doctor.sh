#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
echo "== dxp/doctor.sh =="
chk() {
  if command -v "$2" >/dev/null 2>&1; then
    printf '  ok    %-18s %s\n' "$1" "$(command -v "$2")"
  else
    printf '  MISS  %-18s (%s)\n' "$1" "$2"
  fi
}
chk cargo cargo; chk rustc rustc; chk git git; chk gh gh
chk cosign cosign; chk python3 python3
chk cargo-audit cargo-audit; chk cargo-deny cargo-deny; chk cargo-sbom cargo-sbom
chk launchctl launchctl; chk minisign minisign
python3 -c "import yaml" 2>/dev/null && echo "  ok    pyyaml" || echo "  MISS  pyyaml"
echo
printf '  hooksPath: %s\n' "$(git config core.hooksPath)"
echo
echo "== servers =="
for port in 8080 8081 8082 8083 8084; do
  if curl -sf --max-time 1 "http://127.0.0.1:$port/health" >/dev/null 2>&1 \
  || curl -sf --max-time 1 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
    printf '  ok    :%s\n' "$port"
  else
    printf '  down  :%s\n' "$port"
  fi
done
