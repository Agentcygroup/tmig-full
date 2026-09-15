#!/usr/bin/env bash
# Master license table: HF model hub + SPDX + Creative Commons + custom model licenses.
set -uo pipefail
ROOT="$HOME/tmig-full"
OUT="$ROOT/taxonomy/licenses"
mkdir -p "$OUT"

cat > "$OUT/licenses.tsv" <<'TSV'
id	spdx	category	osi_approved	copyleft	commercial_use	derivatives	share_alike	attribution	notes
apache-2.0	Apache-2.0	permissive	yes	no	yes	yes	no	yes	patent grant; model-friendly
mit	MIT	permissive	yes	no	yes	yes	no	yes	shortest permissive
bsd-2-clause	BSD-2-Clause	permissive	yes	no	yes	yes	no	yes	no patent grant
bsd-3-clause	BSD-3-Clause	permissive	yes	no	yes	yes	no	yes	no endorsement clause
bsd-3-clause-clear	BSD-3-Clause-Clear	permissive	yes	no	yes	yes	no	yes	explicit patent disclaimer
bsd	BSD	permissive	yes	no	yes	yes	no	yes	unspecified variant
bsl-1.0	BSL-1.0	permissive	yes	no	yes	yes	no	yes	Boost software license
isc	ISC	permissive	yes	no	yes	yes	no	yes	similar to MIT
zlib	Zlib	permissive	yes	no	yes	yes	no	yes	short permissive
unlicense	Unlicense	public-domain	yes	no	yes	yes	no	no	public domain dedication
wtfpl	WTFPL	public-domain	yes	no	yes	yes	no	no	do what the fuck you want
cc0-1.0	CC0-1.0	public-domain	yes	no	yes	yes	no	no	CC public domain
pddl	PDDL	public-domain	yes	no	yes	yes	no	no	public domain license
postgresql	PostgreSQL	permissive	yes	no	yes	yes	no	yes	postgres-style
ms-pl	MS-PL	permissive	yes	no	yes	yes	no	yes	microsoft public license
ncsa	NCSA	permissive	yes	no	yes	yes	no	yes	UIUC/NCSA
afl-3.0	AFL-3.0	permissive	yes	no	yes	yes	yes	yes	academic free; patent grant
artistic-2.0	Artistic-2.0	permissive	yes	no	yes	yes	yes	yes	perl artistic 2
mpl-2.0	MPL-2.0	weak-copyleft	yes	partial	yes	yes	yes	yes	file-level copyleft
epl-1.0	EPL-1.0	weak-copyleft	yes	partial	yes	yes	yes	yes	eclipse public 1
epl-2.0	EPL-2.0	weak-copyleft	yes	partial	yes	yes	yes	yes	eclipse public 2
ecl-2.0	ECL-2.0	permissive	yes	no	yes	yes	no	yes	educational community
eupl-1.1	EUPL-1.1	strong-copyleft	yes	yes	yes	yes	yes	yes	EU public license
eupl-1.2	EUPL-1.2	strong-copyleft	yes	yes	yes	yes	yes	yes	EU public license v1.2
osl-3.0	OSL-3.0	strong-copyleft	yes	yes	yes	yes	yes	yes	open software license
cdla-permissive-1.0	CDLA-Permissive-1.0	permissive	yes	no	yes	yes	no	yes	community data license (data)
cdla-permissive-2.0	CDLA-Permissive-2.0	permissive	yes	no	yes	yes	no	yes	data, rev 2
cdla-sharing-1.0	CDLA-Sharing-1.0	copyleft	yes	yes	yes	yes	yes	yes	data, share-alike
odc-by	ODC-By	permissive	yes	no	yes	yes	no	yes	open data attribution
odbl	ODbL	copyleft	yes	yes	yes	yes	yes	yes	open database license
ofl-1.1	OFL-1.1	permissive	yes	no	yes	yes	no	yes	SIL open font license
lppl-1.3c	LPPL-1.3c	permissive	yes	no	yes	yes	no	yes	LaTeX project license
gfdl	GFDL	strong-copyleft	yes	yes	yes	yes	yes	yes	GNU free documentation
gpl	GPL	strong-copyleft	yes	yes	yes	yes	yes	yes	unspecified version
gpl-2.0	GPL-2.0	strong-copyleft	yes	yes	yes	yes	yes	yes	GNU GPL v2
gpl-3.0	GPL-3.0	strong-copyleft	yes	yes	yes	yes	yes	yes	GNU GPL v3
agpl-3.0	AGPL-3.0	network-copyleft	yes	yes	yes	yes	yes	yes	network use triggers distribution
lgpl	LGPL	weak-copyleft	yes	partial	yes	yes	yes	yes	unspecified version
lgpl-2.1	LGPL-2.1	weak-copyleft	yes	partial	yes	yes	yes	yes	GNU LGPL v2.1
lgpl-3.0	LGPL-3.0	weak-copyleft	yes	partial	yes	yes	yes	yes	GNU LGPL v3
lgpl-lr	LGPL-LR	weak-copyleft	yes	partial	yes	yes	yes	yes	LGPL for libraries, less restrictive
cc	CC	creative-commons	no	no	varies	varies	varies	yes	CC umbrella
cc-by-2.0	CC-BY-2.0	creative-commons	no	no	yes	yes	no	yes	CC attribution 2.0
cc-by-2.5	CC-BY-2.5	creative-commons	no	no	yes	yes	no	yes	CC attribution 2.5
cc-by-3.0	CC-BY-3.0	creative-commons	no	no	yes	yes	no	yes	CC attribution 3.0
cc-by-4.0	CC-BY-4.0	creative-commons	no	no	yes	yes	no	yes	CC attribution 4.0
cc-by-sa-3.0	CC-BY-SA-3.0	creative-commons	no	partial	yes	yes	yes	yes	CC share-alike 3.0
cc-by-sa-4.0	CC-BY-SA-4.0	creative-commons	no	partial	yes	yes	yes	yes	CC share-alike 4.0
cc-by-nd-4.0	CC-BY-ND-4.0	creative-commons	no	no	yes	no	no	yes	no derivatives
cc-by-nc-2.0	CC-BY-NC-2.0	creative-commons	no	no	no	yes	no	yes	non-commercial
cc-by-nc-3.0	CC-BY-NC-3.0	creative-commons	no	no	no	yes	no	yes	non-commercial
cc-by-nc-4.0	CC-BY-NC-4.0	creative-commons	no	no	no	yes	no	yes	non-commercial
cc-by-nc-sa-2.0	CC-BY-NC-SA-2.0	creative-commons	no	yes	no	yes	yes	yes	NC + share-alike
cc-by-nc-sa-3.0	CC-BY-NC-SA-3.0	creative-commons	no	yes	no	yes	yes	yes	NC + share-alike
cc-by-nc-sa-4.0	CC-BY-NC-SA-4.0	creative-commons	no	yes	no	yes	yes	yes	NC + share-alike
cc-by-nc-nd-3.0	CC-BY-NC-ND-3.0	creative-commons	no	no	no	no	no	yes	NC + no derivatives
cc-by-nc-nd-4.0	CC-BY-NC-ND-4.0	creative-commons	no	no	no	no	no	yes	NC + no derivatives
openrail	OpenRAIL	model-specific	no	no	yes	yes	no	yes	responsible AI clauses
openrail++	OpenRAIL++	model-specific	no	no	yes	yes	yes	yes	stronger RAIL
openrail-m	OpenRAIL-M	model-specific	no	no	yes	yes	yes	yes	model-specific RAIL
creativeml-openrail-m	CreativeML-OpenRAIL-M	model-specific	no	no	yes	yes	yes	yes	Stable Diffusion 1.x/2.x
bigscience-bloom-rail-1.0	BigScience-BLOOM-RAIL-1.0	model-specific	no	no	yes	yes	yes	yes	BLOOM RAIL
bigscience-openrail-m	BigScience-OpenRAIL-M	model-specific	no	no	yes	yes	yes	yes	BigScience RAIL
bigcode-openrail-m	BigCode-OpenRAIL-M	model-specific	no	no	yes	yes	yes	yes	StarCoder family
llama2	Llama-2-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 2 license
llama3	Llama-3-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 3 license
llama3.1	Llama-3.1-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 3.1
llama3.2	Llama-3.2-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 3.2
llama3.3	Llama-3.3-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 3.3
llama4	Llama-4-Community	model-specific	no	no	varies	varies	no	yes	Meta Llama 4
gemma	Gemma-Terms	model-specific	no	no	varies	varies	yes	yes	Google Gemma
apple-amlr	Apple-AMLR	model-specific	no	no	yes	yes	no	yes	Apple ML research
apple-ascl	Apple-ASCL	model-specific	no	no	varies	varies	no	yes	Apple sample code
c-uda	C-UDA	model-specific	no	no	varies	varies	no	yes	computational use of data
h-research	H-Research	model-specific	no	no	no	yes	no	yes	research only (health)
intel-research	Intel-Research	model-specific	no	no	no	yes	no	yes	research only
deepfloyd-if-license	DeepFloyd-IF	model-specific	no	no	yes	yes	no	yes	DeepFloyd IF model
grok2-community	Grok-2-Community	model-specific	no	no	varies	varies	no	yes	xAI Grok 2
etalab-2.0	Etalab-2.0	open-data	no	no	yes	yes	no	yes	French government
fair-noncommercial-research-license	Fair-NC-Research	research-only	no	no	no	yes	no	yes	non-commercial research
openmdw-1.0	OpenMDW-1.0	model-specific	no	no	yes	yes	no	yes	open model data
openmdw-1.1	OpenMDW-1.1	model-specific	no	no	yes	yes	no	yes	open model data rev 1.1
TSV

# ── classifier script ─────────────────────────────────────────────
cat > "$OUT/classify.py" <<'PY'
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
PY
chmod +x "$OUT/classify.py"

# ── emit as JSON ──────────────────────────────────────────────────
"$HOME/tmig-full/venvs/hf/bin/python" - "$OUT" <<'PY'
import csv, json, pathlib, sys
out = pathlib.Path(sys.argv[1])
rows = list(csv.DictReader(open(out / "licenses.tsv"), delimiter="\t"))
(out / "licenses.json").write_text(json.dumps(rows, indent=2))
print(f"wrote {out}/licenses.json ({len(rows)} licenses)")
PY

# ── emit as USD ───────────────────────────────────────────────────
"$HOME/tmig-full/venvs/hf/bin/python" - "$OUT" <<'PY'
import csv, pathlib, sys, re
from pxr import Usd, Sdf, UsdGeom
out = pathlib.Path(sys.argv[1])
stage = Usd.Stage.CreateNew(str(out / "licenses.usda"))
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
root = UsdGeom.Scope.Define(stage, "/Licenses")
stage.SetDefaultPrim(root.GetPrim())

def safe(n):
    s = "".join(c if c.isalnum() or c == "_" else "_" for c in str(n))
    return ("v_" + s) if (not s or s[0].isdigit()) else s

rows = list(csv.DictReader(open(out / "licenses.tsv"), delimiter="\t"))
for r in rows:
    p = UsdGeom.Xform.Define(stage, f"/Licenses/{safe(r['id'])}")
    for k, v in r.items():
        p.GetPrim().CreateAttribute(safe(k), Sdf.ValueTypeNames.String).Set(str(v))
stage.GetRootLayer().Save()
print(f"wrote {out}/licenses.usda ({sum(1 for _ in stage.Traverse())} prims)")
PY

# ── summary ───────────────────────────────────────────────────────
echo
echo "== category counts =="
"$HOME/tmig-full/venvs/hf/bin/python" "$OUT/classify.py"
echo
echo "== totals =="
wc -l "$OUT/licenses.tsv"
ls -la "$OUT/"
