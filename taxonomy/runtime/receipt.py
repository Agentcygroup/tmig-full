#!/usr/bin/env python3
import sys, json, hashlib, time, pathlib
CHAIN = pathlib.Path.home() / "tmig-full" / "taxonomy" / "runtime" / "receipts" / "chain.jsonl"
CHAIN.parent.mkdir(parents=True, exist_ok=True)
def last():
    if not CHAIN.exists(): return "0"*64
    ls = CHAIN.read_text().strip().splitlines()
    return json.loads(ls[-1])["hash"] if ls else "0"*64
def append(entry):
    entry["ts"] = int(time.time()); entry["prev"] = last()
    entry["hash"] = hashlib.sha256(json.dumps(entry, sort_keys=True).encode()).hexdigest()
    with open(CHAIN, "a") as f: f.write(json.dumps(entry)+"\n")
    return entry["hash"]
def verify():
    if not CHAIN.exists(): return (0,0)
    ok = bad = 0; prev = "0"*64
    for line in CHAIN.read_text().splitlines():
        e = json.loads(line)
        if e["prev"] != prev: bad += 1
        else: ok += 1
        prev = e["hash"]
    return (ok, bad)
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "verify":
        ok, bad = verify(); print(json.dumps({"ok": ok, "broken": bad}))
    elif len(sys.argv) > 1 and sys.argv[1] == "append":
        print(append(json.loads(sys.argv[2]) if len(sys.argv) > 2 else {"event":"test"}))
    else:
        n = sum(1 for _ in open(CHAIN)) if CHAIN.exists() else 0
        print(f"chain: {CHAIN} ({n} entries)")
