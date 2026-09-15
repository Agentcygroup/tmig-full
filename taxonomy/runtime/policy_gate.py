#!/usr/bin/env python3
import json, pathlib, sys
TAX = pathlib.Path.home() / "tmig-full" / "taxonomy"
LIC = TAX / "licenses" / "licenses.json"
TREE = TAX / "model-tree" / "model-tree.json"
def model_license(model):
    if not TREE.exists(): return None
    data = json.loads(TREE.read_text())
    for row in data.get("copyleft", []):
        if row.get("leaf", "").lower() in model.lower():
            return row.get("license")
    return None
def check(model, commercial=False):
    lic = model_license(model)
    if not lic: return (True, f"unknown license for {model}, allowing with warning")
    lic_id = lic.lower().replace("-","").replace("_","")
    tbl = json.loads(LIC.read_text()) if LIC.exists() else []
    row = next((r for r in tbl if r["id"].lower().replace("-","").replace("_","") == lic_id), None)
    if not row: return (True, f"license '{lic}' not in table")
    if commercial and row.get("commercial_use") == "no":
        return (False, f"REFUSED: {model} is {row['id']} — commercial_use=no")
    if row.get("copyleft") == "yes":
        return (True, f"WARN: {model} is {row['id']} (copyleft)")
    return (True, f"ok: {model} is {row['id']} (commercial_use={row['commercial_use']})")
if __name__ == "__main__":
    model = sys.argv[1] if len(sys.argv) > 1 else ""
    commercial = "--commercial" in sys.argv
    ok, msg = check(model, commercial)
    print(msg)
    sys.exit(0 if ok else 2)
