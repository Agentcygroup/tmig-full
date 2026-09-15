#!/usr/bin/env python3
import pathlib, sys, json
try:
    import yaml
except ImportError:
    print("pyyaml missing", file=sys.stderr); sys.exit(2)

ROOT = pathlib.Path(__file__).parent.parent.parent
SCHEMA = json.loads((ROOT/"kernel/schema.json").read_text())

def load(p): return yaml.safe_load(p.read_text())
def has(keys, req): return set(req) <= set(keys)

def check_ext(d):
    ok = True
    for f in ("domain.cedar", "ops.yaml", "entities.yaml", "check.sh"):
        if not (d/f).exists():
            print(f"  FAIL {d.name}: missing {f}"); ok = False
    if not ok: return False
    try:
        ops  = load(d/"ops.yaml").get("ops", [])
        ents = load(d/"entities.yaml").get("entities", [])
    except Exception as e:
        print(f"  FAIL {d.name}: yaml: {e}"); return False
    op_req  = SCHEMA["definitions"]["Op"]["required"]
    ent_req = SCHEMA["definitions"]["Entity"]["required"]
    for o in ops:
        if not has(o, op_req):
            print(f"  FAIL {d.name}: op {o.get('name','?')}"); ok = False
    for e in ents:
        if not has(e, ent_req):
            print(f"  FAIL {d.name}: entity {e.get('kind','?')}"); ok = False
    cedar = (d/"domain.cedar").read_text()
    for o in ops:
        if o["name"] not in cedar:
            print(f"  FAIL {d.name}: op {o['name']} not in domain.cedar"); ok = False
    if ok: print(f"  ok   {d.name}: {len(ops)} ops, {len(ents)} entities")
    return ok

exts = sorted((ROOT/"extensions").glob("*"))
if not exts:
    print("  FAIL no extensions"); sys.exit(1)
failed = 0
for d in exts:
    if d.is_dir() and not check_ext(d): failed += 1
sys.exit(1 if failed else 0)
