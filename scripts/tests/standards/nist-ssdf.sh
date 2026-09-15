#!/usr/bin/env bash
# NIST SP 800-218 PW.4: reusable well-secured software. Every dependency
# is checked by cargo deny; no unmaintained or vulnerable crate.
set -euo pipefail
cd "$(dirname "$0")/../../.."
cargo deny check advisories 2>&1 | tail -2 | grep -q "ok" && echo "nist-ssdf: ok"
