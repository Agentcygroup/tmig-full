#!/usr/bin/env bash
# Verify a signed, attested xt release. No repo access required.
#   verify.sh <tarball> <sig> <cert> <provenance>
set -euo pipefail
TARBALL="$1"; SIG="$2"; CERT="$3"; PROV="$4"

echo "==> cosign verify-blob"
cosign verify-blob \
    --certificate "$CERT" \
    --signature  "$SIG" \
    --certificate-identity-regexp '^https://github.com/Agentcygroup/tmig-full/' \
    --certificate-oidc-issuer   'https://token.actions.githubusercontent.com' \
    "$TARBALL"

echo "==> slsa-verifier"
slsa-verifier verify-artifact "$TARBALL" \
    --provenance-path "$PROV" \
    --source-uri      github.com/Agentcygroup/tmig-full

echo "==> digest"
EXPECTED="$(awk '{print $1}' "${TARBALL}.sha256" 2>/dev/null || true)"
ACTUAL="$(shasum -a 256 "$TARBALL" | awk '{print $1}')"
[ "$EXPECTED" = "$ACTUAL" ] || { echo "digest mismatch"; exit 1; }

echo "OK"
