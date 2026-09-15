"""Regenerate docs/INVARIANTS.md.
Every invariant MUST be enforced by a command that can fail (RFC 2119).
An invariant that SHOULD hold but is not enforced MUST appear in OPEN.md.
"""
import pathlib

scripts = sorted(p.name for p in pathlib.Path("scripts/tests").glob("*.sh")
                 if p.name != "invariants-indexed.sh")
standards = sorted(p.name for p in pathlib.Path("scripts/tests/standards").glob("*.sh"))
rusts = sorted(p.name for p in pathlib.Path(".").glob("crates/*/tests/*.rs"))

lines = [
    "# Invariants", "",
    "Every invariant MUST be enforced by a command that can fail (RFC 2119).",
    "An invariant that SHOULD hold but is not enforced MUST appear in OPEN.md.",
    "",
    "`scripts/tests/invariants-indexed.sh` MUST keep this file in sync.",
    "Regenerate with `python3 scripts/regenerate-invariants.py`.", "",
    "## Shell checks (`scripts/tests/*.sh`)", "",
]
for s in scripts:
    lines.append(f"- `scripts/tests/{s}`")
lines += ["", "## Standards checks (`scripts/tests/standards/*.sh`)", ""]
for s in standards:
    lines.append(f"- `scripts/tests/standards/{s}`")
lines += ["", "## Rust tests (`crates/*/tests/*.rs`)", ""]
for r in rusts:
    lines.append(f"- `{r}`")
lines += ["", "## CLI golden files (`tests/golden/`)", "",
          "- `tests/golden/xt-policy-authorize-allow.txt`",
          "- `tests/golden/sdcl-phases.txt`", ""]

pathlib.Path("docs/INVARIANTS.md").write_text("\n".join(lines) + "\n")
print("regenerated")
