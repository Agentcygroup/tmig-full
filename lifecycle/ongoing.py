#!/usr/bin/env python3
import subprocess, sys, pathlib, datetime
LOG = pathlib.Path.home() / "tmig-full" / "receipts" / "lifecycle-ongoing.log"
LOG.parent.mkdir(parents=True, exist_ok=True)
with LOG.open("a") as f:
    f.write(f"{datetime.datetime.now(datetime.timezone.utc).isoformat()} == cycle ==\n")
r = subprocess.run([sys.executable,
                    str(pathlib.Path.home() / "tmig-full" / "lifecycle" / "reconcile.py")],
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
with LOG.open("a") as f:
    f.write(r.stdout)
print(r.stdout, end="")
sys.exit(r.returncode)
