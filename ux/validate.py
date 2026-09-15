#!/usr/bin/env python3
import pathlib, re, sys, yaml
root = pathlib.Path(__file__).parent.parent
flows    = yaml.safe_load((root/"ux/flows/flows.yaml").read_text())["flows"]
personas = yaml.safe_load((root/"ux/personas.yaml").read_text())["personas"]
dispatcher = (root/"ui/cli/tmig").read_text()
known = set(re.findall(r'^\s+([a-z][a-z0-9-]*)\)', dispatcher, re.M))
bad = []
for flow in flows:
    for step in flow["steps"]:
        parts = step.split()
        if len(parts) < 2 or parts[0] != "tmig":
            bad.append(f"{flow['id']}: bad step '{step}'"); continue
        if parts[1] not in known:
            bad.append(f"{flow['id']}: unknown subcommand '{parts[1]}'")
flow_ids = {f["id"] for f in flows}
for p in personas:
    for f in p["flows"]:
        if f not in flow_ids:
            bad.append(f"persona {p['id']}: unknown flow '{f}'")
if bad:
    for b in bad: print("  FAIL", b)
    sys.exit(1)
print(f"  ok   {len(flows)} flows, {len(personas)} personas")
