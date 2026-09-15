#!/usr/bin/env python3
import hashlib, importlib.util, json, pathlib, sys

IMPL = pathlib.Path.home() / "intent" / "freeze" / "rewrite.py"

def _load():
    spec = importlib.util.spec_from_file_location("rewrite_impl", IMPL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def write_if_changed(path, content):
    p = pathlib.Path(path)
    if isinstance(content, str):
        content = content.encode()
    if p.exists() and p.read_bytes() == content:
        return False
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(content)
    return True

def rewrite(freeze_path, repo):
    mod = _load()
    repo = pathlib.Path(repo).expanduser()
    recs = mod.parse_freeze(pathlib.Path(freeze_path).read_text())

    xt = mod.to_xt_toml(recs)
    if not xt.endswith("\n"):
        xt += "\n"
    w1 = write_if_changed(repo / "xt.toml", xt)

    nc = mod.to_non_claims(recs)
    w2 = write_if_changed(repo / "docs" / "NON_CLAIMS.md", nc)

    payload = json.dumps({"records": recs}, indent=2, sort_keys=True)
    rid = hashlib.sha256(payload.encode()).hexdigest()
    w3 = write_if_changed(repo / "receipts" / "freeze" / f"{rid}.json", payload)

    return {"xt.toml": w1, "docs/NON_CLAIMS.md": w2, f"receipts/freeze/{rid}.json": w3}

def main():
    if len(sys.argv) < 3:
        print("usage: rewrite_lib.py <freeze> <repo>", file=sys.stderr)
        return 2
    for k, v in rewrite(sys.argv[1], sys.argv[2]).items():
        print(f"  {'wrote' if v else 'unchanged'}  {k}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
