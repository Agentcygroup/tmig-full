#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-0.0.1}"
MAX_RETRIES=10
attempt=1

echo "== Initiating Sovereign Mesh Convergence Loop (Tag: $TAG) =="

while [ $attempt -le $MAX_RETRIES ]; do
    echo "--- Convergence Iteration $attempt/$MAX_RETRIES ---"
    
    # 1. Run runtime to refresh node receipts
    if [ -f "sovereign_runtime.py" ]; then
        python3 sovereign_runtime.py || true
    fi
    
    # 2. Poll and merge pending compliance PRs
    if [ -f "poll-and-merge.sh" ]; then
        ./poll-and-merge.sh "$TAG" || true
    fi
    
    # 3. Verify node receipt convergence
    converged=true
    for node in node-01 node-02 node-03; do
        receipt_path="$HOME/receipts/Agentcygroup/mlx-cluster/$node/toroidal_state.json"
        if [ ! -f "$receipt_path" ]; then
            echo "Node [$node]: Missing receipt."
            converged=false
        else
            status=$(jq -r '.status // empty' "$receipt_path" 2>/dev/null || echo "invalid")
            if [ "$status" != "live-operational" ] && [ "$status" != "synchronized" ]; then
                echo "Node [$node]: Status not converged ($status)."
                converged=false
            fi
        fi
    done
    
    # 4. Verify Git working trees are clean on main across repositories
    for repo in team-tmig tmig-full; do
        target_dir="$HOME/$repo"
        if [ -d "$target_dir" ]; then
            cd "$target_dir"
            git checkout main &>/dev/null || true
            git pull origin main &>/dev/null || true
            if [[ -n $(git status --porcelain) ]]; then
                echo "Repo [$repo]: Working tree dirty."
                converged=false
            fi
        fi
    done
    
    cd "$HOME/tmig-full"
    
    if [ "$converged" = true ]; then
        echo "== Closure Convergence Achieved Successfully! All nodes and repositories synchronized. =="
        exit 0
    fi
    
    echo "Convergence pending. Retrying in 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
done

echo "Error: Maximum convergence retries reached."
exit 1
