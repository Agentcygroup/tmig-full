#!/usr/bin/env python3
import pathlib, sys, yaml
root = pathlib.Path(__file__).parent
data = yaml.safe_load((root/"roles.yaml").read_text())
errors = []
if not data.get("name"): errors.append("name missing")
roles = {r["id"] for r in data.get("roles", [])}
for r in data.get("roles", []):
    if not r.get("permissions"): errors.append(f"role {r['id']} has no permissions")
for m in data.get("members", []):
    if m["role"] not in roles:
        errors.append(f"member {m['id']} -> unknown role {m['role']}")
if errors:
    for e in errors: print("  FAIL", e)
    sys.exit(1)
print(f"  ok   {len(roles)} roles, {len(data.get('members', []))} members")
