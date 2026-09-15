#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
kind="${1:?usage: scaffold.sh <crate|recipe|host|check> <name>}"
name="${2:?usage: scaffold.sh <kind> <name>}"
case "$kind" in
  crate)
    mkdir -p "crates/$name/src"
    cat > "crates/$name/Cargo.toml" <<EOF
[package]
name = "$name"
version = "0.1.0"
edition = "2021"
license = "BSD-3-Clause"
EOF
    echo "pub fn hello() -> &'static str { \"$name\" }" > "crates/$name/src/lib.rs"
    echo "  created crates/$name"
    ;;
  recipe)
    cat > "infra/recipes/$name.yaml" <<EOF
apiVersion: tmig.io/v1
kind: Recipe
metadata: {name: $name, version: "0.1.0"}
spec:
  units: []
EOF
    echo "  created infra/recipes/$name.yaml"
    ;;
  host)
    cat > "infra/hosts/$name.yaml" <<EOF
apiVersion: tmig.io/v1
kind: Host
metadata: {name: $name, signed: false}
spec:
  recipes: []
  sandbox: [/Users/metadusa]
EOF
    echo "  created infra/hosts/$name.yaml"
    ;;
  check)
    cat > "scripts/check-$name.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
echo "  ok   $name"
EOF
    chmod +x "scripts/check-$name.sh"
    echo "  created scripts/check-$name.sh"
    ;;
  *) echo "unknown kind: $kind"; exit 1 ;;
esac
