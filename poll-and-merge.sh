#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-0.0.1}"
echo "== Polling ranked polyglot merge gate (Tag: $TAG) =="

for repo in team-tmig tmig-full; do
  target_dir="$HOME/$repo"
  [[ -d "$target_dir" ]] || continue
  cd "$target_dir"
  PR_NUM=$(gh pr list --head "fix/mesh-compliance" --json number --jq '.[0].number' || true)
  [[ -n "${PR_NUM:-}" ]] || continue

  echo "Monitoring PR #$PR_NUM on Agentcygroup/$repo..."
  while true; do
    STATUS=$(gh pr checks "$PR_NUM" --json name,state --jq '.[] | select(.name=="gate") | .state' | head -1)
    case "${STATUS:-PENDING}" in
      SUCCESS|COMPLETED) break ;;
      FAILURE|ERROR|CANCELLED|TIMED_OUT)
        echo "DENY_LAND: required 'gate' check is $STATUS" >&2
        exit 1
        ;;
      *)
        echo "Awaiting gate check: ${STATUS:-PENDING}"
        sleep 10
        ;;
    esac
  done

  # No --admin bypass. Repository rules remain authoritative.
  gh pr merge "$PR_NUM" --squash --delete-branch
  git checkout main
  git pull --ff-only origin main
done

echo "== Ranked delta + harness + ledger gate satisfied =="
