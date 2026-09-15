"""Regenerate docs/INVARIANTS.md from the files on disk."""
import pathlib

scripts = sorted(p.name for p in pathlib.Path("scripts/tests").glob("*.sh")
                 if p.name != "invariants-indexed.sh")
rusts = sorted(p.name for p in pathlib.Path(".").glob("crates/*/tests/*.rs"))

lines = ["# Invariants", "",
         "Every invariant is a property a command can fail on. This file is",
         "the index. `scripts/tests/invariants-indexed.sh` verifies the two",
         "stay in sync. Regenerate with:", "",
         "```bash", "python3 scripts/regenerate-invariants.py", "```", "",
         "## Shell checks (`scripts/tests/*.sh`)", ""]
for s in scripts:
    lines.append(f"- `scripts/tests/{s}`")
lines += ["", "## Rust tests (`crates/*/tests/*.rs`)", ""]
for r in rusts:
    lines.append(f"- `{r}`")
lines += ["", "## CLI golden files (`tests/golden/`)", "",
          "- `tests/golden/xt-policy-authorize-allow.txt`",
          "- `tests/golden/sdcl-phases.txt`", ""]

pathlib.Path("docs/INVARIANTS.md").write_text("\n".join(lines) + "\n")
print("regenerated")
