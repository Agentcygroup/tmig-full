#!/usr/bin/env bash
# Every Action referenced by a Behavior MUST have at least one Emergence
# prim binding it to that Behavior. Every rel target MUST resolve.
set -euo pipefail
cd "$(dirname "$0")/../.."

[ -f spec/emergence/emergence.usda ] || { echo "FAIL: emergence.usda missing"; exit 1; }

fail=0
# 1. Every Emergence's rels must point at existing Action/Behavior prims.
while IFS= read -r line; do
    case "$line" in
        *from_action*)   target=$(sed 's/.*<\/Actions\/\([a-z]*\)>.*/\1/' <<<"$line")
                          grep -q "def Action \"$target\"" spec/actions/actions.usda || { echo "FAIL: emergence refers to unknown Action $target"; fail=1; } ;;
        *from_behavior*) target=$(sed 's/.*<\/Behaviors\/\([a-z-]*\)>.*/\1/' <<<"$line")
                          grep -q "def Behavior \"$target\"" spec/behaviors/behaviors.usda || { echo "FAIL: emergence refers to unknown Behavior $target"; fail=1; } ;;
    esac
done < <(grep -E 'rel +(from_action|from_behavior)' spec/emergence/emergence.usda)

# 2. Every Action must appear as a from_action of at least one Emergence.
for a in $(grep -oE 'def Action "[a-z]+"' spec/actions/actions.usda | sed 's/.*"\(.*\)"/\1/'); do
    grep -q "from_action = </Actions/$a>" spec/emergence/emergence.usda || {
        echo "FAIL: Action $a has no Emergence prim"; fail=1; }
done

# 3. Every Behavior must appear as a from_behavior of at least one Emergence.
for b in $(grep -oE 'def Behavior "[a-z0-9-]+"' spec/behaviors/behaviors.usda | sed 's/.*"\(.*\)"/\1/'); do
    grep -q "from_behavior = </Behaviors/$b>" spec/emergence/emergence.usda || {
        echo "FAIL: Behavior $b has no Emergence prim"; fail=1; }
done

[ $fail -eq 0 ] && echo "emergence-covered: ok" || exit 1
