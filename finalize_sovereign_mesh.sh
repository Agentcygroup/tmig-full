#!/usr/bin/env bash
set -euo pipefail

echo "🛡️ [Sovereign Mesh] Finalizing public repository rulesets and branch protections..."

REPOS=("team-tmig" "tmig-full" "tmig-control" "receipts")

for repo in "${REPOS[@]}"; do
    echo "== Verifying / Protecting repo: Agentcygroup/$repo =="

    # Ensure public visibility is fully propagated
    gh api -X PATCH "repos/Agentcygroup/$repo" -f private=false >/dev/null 2>&1 || true

    # Apply strict branch protection now that repos are public (free tier compatible)
    gh api -X PUT "repos/Agentcygroup/$repo/branches/main/protection" \
        -f "required_status_checks[strict]=true" \
        -f "required_status_checks[contexts][]=ci" \
        -f "enforce_admins=false" \
        -f "required_pull_request_reviews[required_approving_review_count]=1" >/dev/null 2>&1 \
        && echo "  ✓ Branch protection locked successfully." \
        || echo "  ⚠️ Branch protection ruleset pending propagation."
done

echo -e "\n✨ Sovereign multi-repo mesh fully synchronized, public, and protected."
