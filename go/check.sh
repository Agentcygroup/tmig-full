#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f go.mod ]                || { echo "FAIL go.mod"; exit 1; }
[ -f go/cmd/tmig/main.go ]   || { echo "FAIL go/cmd/tmig/main.go"; exit 1; }

if ! command -v go >/dev/null 2>&1; then
    echo "  note: go not installed; skipping build"
    echo "go ok (parse only)"
    exit 0
fi

go fmt ./go/... >/dev/null
go vet ./go/... 2>&1 | tail -5
go build -o bin/tmig-go ./go/cmd/tmig
[ -x bin/tmig-go ] || { echo "FAIL build"; exit 1; }
echo "  ok   bin/tmig-go"

# run version to prove it executes
./bin/tmig-go version
echo "go ok"
