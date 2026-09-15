#!/usr/bin/env bash
# Download a model only if free disk > 2× estimated size. Skip otherwise.
set -uo pipefail
HF="$HOME/tmig-full/venvs/hf/bin/hf"
[ -x "$HF" ] || { echo "no hf binary"; exit 1; }
declare -A SIZES=(
  ["mistralai/Mixtral-8x22B-Instruct-v0.1"]=280
  ["mistralai/Mixtral-8x7B-Instruct-v0.1"]=95
  ["meta-llama/Llama-3.1-70B-Instruct"]=140
  ["meta-llama/Llama-3.1-8B"]=16
  ["Qwen/Qwen2.5-72B-Instruct"]=145
  ["stabilityai/stable-video-diffusion-img2vid-xt"]=20
  ["THUDM/CogVideoX-2b"]=15
  ["Salesforce/blip2-opt-2.7b"]=30
)
for repo in "$@"; do
  need=${SIZES[$repo]:-10}
  free=$(df -g "$HOME" | awk 'NR==2 {print $4}')
  if [ "$free" -lt $((need * 2)) ]; then
    echo "SKIP $repo: need $((need*2))GB, free ${free}GB"
    continue
  fi
  echo "OK   $repo ($need GB est, $free GB free)"
  "$HF" download "$repo"
done
