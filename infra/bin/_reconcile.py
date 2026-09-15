#!/usr/bin/env python3
"""_reconcile.py — the reconciler engine.

Reads desired state (YAML), reads observed state, computes a diff,
applies it, writes a receipt. No network. No external service.
"""
import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import time

try:
    import yaml
except ImportError:
    print("_reconcile.py: pyyaml missing (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)


def load(path):
    with open(path) as f:
        return yaml.safe_load(f)


def observe(root, host):
    """Recompute the observed state by probing the actual system."""
    observed = {"host": host, "ts": int(time.time()), "units": {}}
    for recipe_path in sorted((root / "recipes").glob("*.yaml")):
        recipe = load(recipe_path)
        for unit in recipe["spec"]["units"]:
            key = f"{recipe['metadata']['name']}/{unit['name']}"
            kind = unit["kind"]
            if kind == "file":
                p = pathlib.Path(unit["path"])
                if p.exists():
                    data = p.read_bytes()
                    observed["units"][key] = {
                        "kind": "file",
                        "present": True,
                        "sha256": hashlib.sha256(data).hexdigest(),
                    }
                else:
                    observed["units"][key] = {"kind": "file", "present": False}
            elif kind == "service":
                label = unit["label"]
                r = subprocess.run(
                    ["launchctl", "list"],
                    capture_output=True, text=True,
                )
                observed["units"][key] = {
                    "kind": "service",
                    "loaded": label in r.stdout,
                }
            else:
                observed["units"][key] = {"kind": kind, "unknown": True}
    return observed


def desired_digest(root, unit, recipe_name):
    """Digest the recipe's declaration of a unit."""
    return hashlib.sha256(
        json.dumps({"recipe": recipe_name, "unit": unit}, sort_keys=True).encode()
    ).hexdigest()


def plan(root, desired, observed):
    """Produce the list of actions required to converge."""
    actions = []
    for recipe_name in desired["spec"]["recipes"]:
        recipe_path = root / "recipes" / f"{recipe_name}.yaml"
        if not recipe_path.exists():
            actions.append({"kind": "missing-recipe", "recipe": recipe_name})
            continue
        recipe = load(recipe_path)
        for unit in recipe["spec"]["units"]:
            key = f"{recipe_name}/{unit['name']}"
            obs = observed["units"].get(key, {})
            kind = unit["kind"]
            if kind == "file":
                if not obs.get("present"):
                    actions.append({"kind": "write-file", "unit": unit, "recipe": recipe_name})
                else:
                    src = (root / "units" / pathlib.Path(unit["source"]).name).read_bytes()
                    want = hashlib.sha256(src).hexdigest()
                    if obs.get("sha256") != want:
                        actions.append({"kind": "write-file", "unit": unit, "recipe": recipe_name})
            elif kind == "service":
                if not obs.get("loaded"):
                    actions.append({"kind": "load-service", "unit": unit, "recipe": recipe_name})
    return actions


def apply(root, action):
    kind = action["kind"]
    if kind == "write-file":
        unit = action["unit"]
        src = root / "units" / pathlib.Path(unit["source"]).name
        dst = pathlib.Path(unit["path"])
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(src.read_bytes())
        os.chmod(dst, int(unit.get("mode", "0644"), 8))
        return {"applied": "write-file", "path": str(dst)}
    if kind == "load-service":
        unit = action["unit"]
        plist = pathlib.Path("/Users/metadusa/Library/LaunchAgents") / f"{unit['label']}.plist"
        if plist.exists():
            subprocess.run(["launchctl", "unload", str(plist)], capture_output=True)
            subprocess.run(["launchctl", "load", str(plist)], capture_output=True)
        return {"applied": "load-service", "label": unit["label"]}
    if kind == "missing-recipe":
        return {"skipped": "missing-recipe", "recipe": action["recipe"]}
    return {"skipped": kind}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--host", required=True)
    ap.add_argument("--desired", required=True)
    ap.add_argument("--observed", required=True)
    ap.add_argument("--receipt", required=True)
    args = ap.parse_args()

    root = pathlib.Path(args.root)
    desired = load(args.desired)

    print(f"  observing {args.host}...")
    observed = observe(root, args.host)
    pathlib.Path(args.observed).write_text(json.dumps(observed, indent=2))

    print("  planning...")
    actions = plan(root, desired, observed)

    if not actions:
        receipt = {
            "host": args.host, "ts": int(time.time()),
            "converged": True, "actions": [],
        }
        pathlib.Path(args.receipt).write_text(json.dumps(receipt, indent=2))
        print("  no drift")
        return 0

    print(f"  {len(actions)} action(s) required")
    applied = []
    for a in actions:
        print(f"    {a['kind']}: {a.get('unit', {}).get('name', a.get('recipe', '?'))}")
        applied.append(apply(root, a))

    receipt = {
        "host": args.host, "ts": int(time.time()),
        "converged": False, "actions": actions, "applied": applied,
    }
    pathlib.Path(args.receipt).write_text(json.dumps(receipt, indent=2))
    return 1


if __name__ == "__main__":
    sys.exit(main())
