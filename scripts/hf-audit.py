#!/usr/bin/env python3
"""Audit HF cache: what's downloaded, what's partial, what's missing from the catalog."""
import json, pathlib, sys

ROOT = pathlib.Path.home() / "tmig-full"
CACHE = pathlib.Path.home() / ".cache" / "huggingface" / "hub"
CAT = ROOT / "model-catalog" / "catalog.json"

# 1. everything in the catalog
want = set()
if CAT.exists():
    data = json.loads(CAT.read_text())
    for e in data.values():
        m = e.get("model")
        if m and "/" in m:
            want.add(m)
        for vs in e.get("variants", {}).values():
            for a in vs.get("arch", {}).values():
                m = a.get("model")
                if m and "/" in m:
                    want.add(m)

# 2. everything in the cache
have = set()
partial = set()
for d in CACHE.glob("models--*"):
    repo = d.name[len("models--"):].replace("--", "/")
    # check for incomplete blobs
    blobs = d / "blobs"
    incomplete = list(blobs.glob("*.incomplete")) if blobs.exists() else []
    if incomplete:
        partial.add(repo)
    else:
        have.add(repo)

# 3. report
print(f"== cache audit ==")
print(f"  catalog references:  {len(want)}")
print(f"  fully downloaded:    {len(have)}")
print(f"  partially downloaded: {len(partial)}")
print(f"  missing:             {len(want - have - partial)}")
print()

missing = want - have - partial
if missing:
    print("== missing from cache ==")
    for m in sorted(missing):
        print(f"  {m}")
    print()

if partial:
    print("== partial (has .incomplete blobs — delete and retry) ==")
    for m in sorted(partial):
        d = CACHE / ("models--" + m.replace("/", "--"))
        blobs = list((d / "blobs").glob("*.incomplete"))
        total = sum(b.stat().st_size for b in blobs)
        print(f"  {m}  ({len(blobs)} incomplete, {total/1024/1024:.1f} MB)")
    print()

# 4. disk space
import subprocess
r = subprocess.run(["df", "-h", str(pathlib.Path.home())], capture_output=True, text=True)
print("== disk space ==")
print(r.stdout)

# 5. cache size
def du(p):
    if not p.exists(): return 0
    total = 0
    for f in p.rglob("*"):
        # skip symlinks — hf_hub uses them in snapshots/, counting them double-counts blobs
        if f.is_file() and not f.is_symlink():
            try: total += f.stat().st_size
            except: pass
    return total

print(f"== cache size ==")
print(f"  total: {du(CACHE)/1024**3:.1f} GB")
