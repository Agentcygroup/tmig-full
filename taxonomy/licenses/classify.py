#!/usr/bin/env python3
"""Classify every license id into category + commercial viability."""
import sys, csv, pathlib, json
OUT = pathlib.Path(__file__).parent
rows = list(csv.DictReader(open(OUT / "licenses.tsv"), delimiter="\t"))

def lookup(lid):
    for r in rows:
        if r["id"] == lid:
            return r
    return None

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        for r in rows:
            print(f"{r['id']:<40} {r['spdx']:<26} {r['category']:<20} commercial={r['commercial_use']}")
    elif len(sys.argv) > 1:
        r = lookup(sys.argv[1])
        if r: print(json.dumps(r, indent=2))
        else: print(f"unknown: {sys.argv[1]}")
    else:
        # summary counts
        from collections import Counter
        c = Counter(r["category"] for r in rows)
        for k, v in sorted(c.items()): print(f"{k:<24} {v}")
