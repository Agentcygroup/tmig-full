#!/usr/bin/env bash
# Every line in docs/*.md containing a claim verb must either cite a test
# file or carry an explicit "nonclaim:" prefix.
set -euo pipefail
cd "$(dirname "$0")/../.."

[ -d docs ] || { echo "docs-claims: no docs/; skip"; exit 0; }
VERBS='guarantees|proves|ensures|always|never fails|cannot'
fail=0
while IFS= read -r line; do
    case "$line" in
        *"nonclaim:"*|*"# "*|*"//"*) continue ;;
    esac
    if grep -qiE "$VERBS" <<<"$line"; then
        if ! grep -qE 'tests?/|\.rs|make [a-z-]+' <<<"$line"; then
            echo "FAIL: uncited claim in docs: $line"
            fail=1
        fi
    fi
done < <(cat docs/*.md 2>/dev/null || true)
[ $fail -eq 0 ] && echo "docs-claims: ok" || exit 1
