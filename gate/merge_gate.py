#!/usr/bin/env python3
"""Fail-closed polyglot merge gate for tmig-full.

Three independent inputs are required for land:
  1. ranked delta set generated from the git range,
  2. harness result with all required checks PASS,
  3. ledger grade meeting the minimum required by the highest-risk delta.

Python 3.9+ stdlib only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import subprocess
import sys
from typing import Any, Dict, Iterable, List, Tuple

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = ROOT / "gate" / "config.json"


def load_json(path: pathlib.Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected JSON object")
    return data


def dump_json(path: pathlib.Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")
    tmp.replace(path)


def sha256_json(data: Dict[str, Any]) -> str:
    payload = json.dumps(data, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def run_git(args: List[str]) -> str:
    cp = subprocess.run(["git", *args], cwd=ROOT, text=True, capture_output=True)
    if cp.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {cp.stderr.strip()}")
    return cp.stdout


def classify_language(path: str, config: Dict[str, Any]) -> str:
    if path == "Cargo.toml" or path == "Cargo.lock" or path.startswith("crates/"):
        if pathlib.PurePosixPath(path).suffix in {".rs", ""} or path in {"Cargo.toml", "Cargo.lock"}:
            return "rust"
    if path in {"go.mod", "go.sum"}:
        return "go"
    suffix = pathlib.PurePosixPath(path).suffix.lower()
    return config["language_extensions"].get(suffix, "other")


def path_starts_or_equals(path: str, rule: str) -> bool:
    if rule.endswith("/"):
        return path.startswith(rule)
    return path == rule


def score_delta(path: str, change: str, adds: int, deletes: int, config: Dict[str, Any]) -> Tuple[int, List[str]]:
    score = 20
    reasons: List[str] = ["tracked change"]
    if any(path_starts_or_equals(path, r) for r in config["critical_paths"]):
        score = max(score, 90)
        reasons.append("critical control/authority path")
    elif any(path_starts_or_equals(path, r) for r in config["high_paths"]):
        score = max(score, 70)
        reasons.append("runtime/implementation path")
    if change.startswith("D"):
        score += 8
        reasons.append("deletion")
    elif change.startswith("R"):
        score += 5
        reasons.append("rename")
    churn = adds + deletes
    if churn >= 500:
        score += 10
        reasons.append("large churn >=500")
    elif churn >= 100:
        score += 5
        reasons.append("churn >=100")
    return min(score, 100), reasons


def rank_for_score(score: int, config: Dict[str, Any]) -> str:
    thresholds = config["rank_thresholds"]
    for rank in ("critical", "high", "medium", "low"):
        if score >= int(thresholds[rank]):
            return rank
    return "low"


def parse_numstat(base: str, head: str) -> Dict[str, Tuple[int, int]]:
    stats: Dict[str, Tuple[int, int]] = {}
    out = run_git(["diff", "--numstat", f"{base}...{head}"])
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        a, d, p = parts[0], parts[1], parts[-1]
        adds = 0 if a == "-" else int(a)
        dels = 0 if d == "-" else int(d)
        stats[p] = (adds, dels)
    return stats


def parse_name_status(base: str, head: str) -> List[Tuple[str, str]]:
    rows: List[Tuple[str, str]] = []
    out = run_git(["diff", "--name-status", f"{base}...{head}"])
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        rows.append((parts[0], parts[-1]))
    return rows


def cmd_rank(args: argparse.Namespace) -> int:
    config = load_json(pathlib.Path(args.config))
    stats = parse_numstat(args.base, args.head)
    deltas: List[Dict[str, Any]] = []
    for status, path in parse_name_status(args.base, args.head):
        adds, deletes = stats.get(path, (0, 0))
        score, reasons = score_delta(path, status, adds, deletes, config)
        deltas.append({
            "delta_id": hashlib.sha256(f"{status}\0{path}\0{adds}\0{deletes}".encode()).hexdigest()[:16],
            "path": path,
            "change": status,
            "additions": adds,
            "deletions": deletes,
            "language": classify_language(path, config),
            "score": score,
            "rank": rank_for_score(score, config),
            "reasons": reasons,
        })
    deltas.sort(key=lambda d: (-d["score"], d["path"]))
    required_languages = sorted({d["language"] for d in deltas if d["language"] not in {"other", "config"}})
    doc = {
        "schema": "tmig.merge.delta.v1",
        "base": args.base,
        "head": args.head,
        "count": len(deltas),
        "required_languages": required_languages,
        "deltas": deltas,
    }
    doc["digest"] = sha256_json(doc)
    dump_json(pathlib.Path(args.output), doc)
    print(f"ranked {len(deltas)} deltas -> {args.output}")
    return 0


def read_jsonl(paths: Iterable[pathlib.Path]) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in paths:
        if not path.exists():
            continue
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as e:
                raise ValueError(f"{path}:{n}: invalid JSON: {e}") from e
            if not isinstance(row, dict):
                raise ValueError(f"{path}:{n}: ledger row must be object")
            rows.append(row)
    return rows


def cmd_grade(args: argparse.Namespace) -> int:
    rows = read_jsonl([pathlib.Path(p) for p in args.ledger])
    if not rows:
        raise ValueError("ledger contains no current-run rows")
    valid_status = {"PASS", "FAIL", "SKIP"}
    if any(r.get("status") not in valid_status for r in rows):
        raise ValueError("ledger contains unknown status")
    required = [r for r in rows if bool(r.get("required", True))]
    passed = sum(r.get("status") == "PASS" for r in required)
    failed = sum(r.get("status") == "FAIL" for r in required)
    skipped = sum(r.get("status") == "SKIP" for r in required)
    total = len(required)
    coverage = passed / total if total else 0.0
    if failed > 0 or total == 0:
        grade = "F"
    elif skipped > 0:
        grade = "C" if coverage >= 0.80 else "D"
    elif coverage == 1.0:
        grade = "A"
    elif coverage >= 0.95:
        grade = "B"
    elif coverage >= 0.80:
        grade = "C"
    else:
        grade = "D"
    normalized_rows = sorted(rows, key=lambda r: (str(r.get("check", "")), str(r.get("language", ""))))
    doc = {
        "schema": "tmig.merge.ledger-grade.v1",
        "grade": grade,
        "required_total": total,
        "required_passed": passed,
        "required_failed": failed,
        "required_skipped": skipped,
        "coverage": round(coverage, 6),
        "row_digest": hashlib.sha256(json.dumps(normalized_rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest(),
    }
    doc["digest"] = sha256_json(doc)
    dump_json(pathlib.Path(args.output), doc)
    print(f"ledger grade {grade} ({passed}/{total} required PASS) -> {args.output}")
    return 0 if grade != "F" else 1


def max_delta_rank(delta: Dict[str, Any]) -> str:
    order = {"low": 0, "medium": 1, "high": 2, "critical": 3}
    ranks = [str(d.get("rank", "critical")) for d in delta.get("deltas", [])]
    return max(ranks, key=lambda r: order.get(r, 99)) if ranks else "low"


def fail_reasons(delta: Dict[str, Any], harness: Dict[str, Any], ledger: Dict[str, Any], config: Dict[str, Any]) -> List[str]:
    reasons: List[str] = []
    if delta.get("schema") != "tmig.merge.delta.v1":
        reasons.append("delta schema invalid")
    if harness.get("schema") != "tmig.merge.harness.v1":
        reasons.append("harness schema invalid")
    if ledger.get("schema") != "tmig.merge.ledger-grade.v1":
        reasons.append("ledger-grade schema invalid")
    if harness.get("status") != "PASS":
        reasons.append("harness status is not PASS")
    required_langs = set(delta.get("required_languages", []))
    checked_langs = {c.get("language") for c in harness.get("checks", []) if c.get("status") == "PASS"}
    missing = sorted(required_langs - checked_langs)
    if missing:
        reasons.append("uncovered delta languages: " + ", ".join(missing))
    checks = [c for c in harness.get("checks", []) if c.get("required", True)]
    bad = [str(c.get("check", "?")) for c in checks if c.get("status") != "PASS"]
    if bad:
        reasons.append("required harness checks not PASS: " + ", ".join(sorted(bad)))
    highest = max_delta_rank(delta)
    required_grade = config["minimum_ledger_grade_by_delta_rank"][highest]
    actual_grade = str(ledger.get("grade", "F"))
    points = config["grade_points"]
    if actual_grade not in points or points[actual_grade] < points[required_grade]:
        reasons.append(f"ledger grade {actual_grade} below {required_grade} required for {highest} delta")
    if int(ledger.get("required_failed", 1)) != 0:
        reasons.append("ledger contains required FAIL")
    if int(ledger.get("required_skipped", 1)) != 0:
        reasons.append("ledger contains required SKIP")
    return reasons


def cmd_evaluate(args: argparse.Namespace) -> int:
    config = load_json(pathlib.Path(args.config))
    delta = load_json(pathlib.Path(args.delta))
    harness = load_json(pathlib.Path(args.harness))
    ledger = load_json(pathlib.Path(args.ledger_grade))
    reasons = fail_reasons(delta, harness, ledger, config)
    decision = "ALLOW_LAND" if not reasons else "DENY_LAND"
    highest = max_delta_rank(delta)
    required_grade = config["minimum_ledger_grade_by_delta_rank"][highest]
    doc = {
        "schema": "tmig.merge.land-decision.v1",
        "decision": decision,
        "delta_digest": delta.get("digest"),
        "harness_digest": harness.get("digest"),
        "ledger_grade_digest": ledger.get("digest"),
        "highest_delta_rank": highest,
        "required_ledger_grade": required_grade,
        "actual_ledger_grade": ledger.get("grade"),
        "reasons": reasons,
    }
    doc["decision_digest"] = sha256_json(doc)
    dump_json(pathlib.Path(args.output), doc)
    if decision == "ALLOW_LAND":
        print(f"ALLOW_LAND digest={doc['decision_digest']}")
        return 0
    print("DENY_LAND: " + "; ".join(reasons), file=sys.stderr)
    return 1


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Rank deltas, grade ledger, and decide whether a change may land.")
    p.add_argument("--config", default=str(DEFAULT_CONFIG))
    sub = p.add_subparsers(dest="command", required=True)

    rank = sub.add_parser("rank")
    rank.add_argument("--base", required=True)
    rank.add_argument("--head", required=True)
    rank.add_argument("--output", required=True)
    rank.set_defaults(func=cmd_rank)

    grade = sub.add_parser("grade-ledger")
    grade.add_argument("--ledger", action="append", required=True)
    grade.add_argument("--output", required=True)
    grade.set_defaults(func=cmd_grade)

    ev = sub.add_parser("evaluate")
    ev.add_argument("--delta", required=True)
    ev.add_argument("--harness", required=True)
    ev.add_argument("--ledger-grade", required=True)
    ev.add_argument("--output", required=True)
    ev.set_defaults(func=cmd_evaluate)
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        return int(args.func(args))
    except (OSError, ValueError, RuntimeError) as e:
        print(f"merge-gate error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
