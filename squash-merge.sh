#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-0.0.1}"
echo "== Gate-enforced squash merge (Tag: $TAG) =="

for repo in team-tmig tmig-full; do
  target_dir="$HOME/$repo"
  [[ -d "$target_dir" ]] || continue
  cd "$target_dir"
  PR_NUM=$(gh pr list --head fix/workflow-dispatch --json number --jq '.[0].number' || true)
  [[ -n "${PR_NUM:-}" ]] || continue

  STATUS=$(gh pr checks "$PR_NUM" --json name,state --jq '.[] | select(.name=="gate") | .state' | head -1)
  if [[ "$STATUS" != "SUCCESS" && "$STATUS" != "COMPLETED" ]]; then
    echo "DENY_LAND: PR #$PR_NUM lacks successful required 'gate' check (got ${STATUS:-MISSING})" >&2
    exit 1
  fi

  # Deliberately no --admin and no failure suppression.
  gh pr merge "$PR_NUM" --squash --delete-branch
  git checkout main
  git pull --ff-only origin main
done

echo "== Ranked delta + harness + ledger gate satisfied =="
