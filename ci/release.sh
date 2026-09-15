#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:?usage: release.sh <vX.Y.Z>}"
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "bad version"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "dirty tree"; exit 1; }

scripts/local-verify.sh >/dev/null
./target/release/xt release
TARBALL=$(ls -t out/xt-*.tar.gz | head -1)
cosign sign-blob --yes --bundle "${TARBALL}.bundle" "$TARBALL"
git tag -s "$version" -m "$version"
git push origin main
git push origin "$version"
gh release create "$version" "$TARBALL" "${TARBALL}.sha256" "${TARBALL}.bundle" \
  --title "$version" --notes "Reproducible, policy-gated."
echo "released $version"
