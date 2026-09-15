#!/usr/bin/env python3
import subprocess, sys, pathlib

RECONCILE = pathlib.Path.home() / "tmig-full" / "lifecycle" / "reconcile.py"

def main():
    print("== reconcile ==")
    r = subprocess.run([sys.executable, str(RECONCILE)])
    return r.returncode

if __name__ == "__main__":
    sys.exit(main())
