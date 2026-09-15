#!/usr/bin/env python3
import json, pathlib, subprocess, time
RUNT = pathlib.Path.home() / "tmig-full" / "taxonomy" / "runtime"
CHAIN = RUNT / "receipts" / "chain.jsonl"
ARCH = RUNT / "receipts" / "archived"
ARCH.mkdir(parents=True, exist_ok=True)
ROTATE_EVERY = 10
def main():
    if not CHAIN.exists(): print("no chain yet"); return
    lines = CHAIN.read_text().splitlines()
    n = len(lines)
    if n < ROTATE_EVERY: print(f"chain has {n} entries, threshold {ROTATE_EVERY}"); return
    segments = n // ROTATE_EVERY
    for s in range(segments):
        seg = lines[s*ROTATE_EVERY:(s+1)*ROTATE_EVERY]
        last = json.loads(seg[-1]); h = last["hash"]
        try:
            r = subprocess.run(
                ["ssh-keygen","-Y","sign","-f",str(pathlib.Path.home()/".ssh"/"id_ed25519"),
                 "-n","receipt-rotation","-"],
                input=h.encode(), capture_output=True, check=False)
            sig = r.stdout.decode(errors="ignore") if r.returncode == 0 else "(no signature)"
        except Exception: sig = "(no ssh-keygen)"
        out = ARCH / f"segment-{s:04d}.json"
        out.write_text(json.dumps({"segment":s,"start":s*ROTATE_EVERY,
            "end":(s+1)*ROTATE_EVERY-1,"last_hash":h,"signature":sig,
            "entries":seg,"archived_at":int(time.time())}, indent=2))
        print(f"archived segment {s}")
    tail = lines[segments * ROTATE_EVERY:]
    CHAIN.write_text("\n".join(tail) + ("\n" if tail else ""))
if __name__ == "__main__": main()
