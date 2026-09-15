#!/usr/bin/env python3
import sys, json, pathlib, sqlite3
from pxr import Usd
TAX = pathlib.Path.home() / "tmig-full" / "taxonomy"
MEM = TAX / "runtime" / "memory"; MEM.mkdir(parents=True, exist_ok=True)
DB = MEM / "prims.db"
def init():
    c = sqlite3.connect(DB)
    c.execute("CREATE TABLE IF NOT EXISTS prims(path TEXT PRIMARY KEY, domain TEXT, name TEXT, data TEXT, indexed_at INTEGER)")
    c.execute("CREATE VIRTUAL TABLE IF NOT EXISTS prims_fts USING fts5(path, domain, name, data)")
    c.commit(); return c
def index():
    c = init(); n = 0
    for usd in TAX.glob("*/*.usda"):
        try:
            s = Usd.Stage.Open(str(usd))
            if not s: continue
            for prim in s.Traverse():
                p = str(prim.GetPath()); parts = p.split("/")
                d = parts[1] if len(parts) > 1 else ""; nm = parts[-1]
                attrs = {}
                for a in prim.GetAttributes():
                    try: attrs[a.GetName()] = a.Get()
                    except Exception: pass
                data = json.dumps(attrs)
                c.execute("INSERT OR REPLACE INTO prims VALUES (?,?,?,?,strftime('%s','now'))", (p,d,nm,data))
                c.execute("INSERT INTO prims_fts VALUES (?,?,?,?)", (p,d,nm,data))
                n += 1
        except Exception as e:
            print(f"skip {usd}: {e}", file=sys.stderr)
    c.commit(); c.close(); return n
def search(q, limit=10):
    c = init()
    rows = c.execute("SELECT path,domain,name FROM prims_fts WHERE prims_fts MATCH ? LIMIT ?", (q,limit)).fetchall()
    c.close(); return [{"path":r[0],"domain":r[1],"name":r[2]} for r in rows]
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "index":
        print(f"indexed {index()} prims into {DB}")
    elif len(sys.argv) > 1:
        print(json.dumps(search(sys.argv[1]), indent=2))
    else:
        print(f"db: {DB}")
