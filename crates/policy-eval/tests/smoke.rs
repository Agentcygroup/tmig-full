// This test does not exercise Cedar itself (that's the main binary).
// It verifies the decision table is well-formed and reachable from the
// crate's expected path. If it fails, the policy-eval binary will too.

use std::path::PathBuf;

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

#[test]
fn decision_table_is_present_and_well_formed() {
    let path = repo_root().join("policy/tests/decision-table.json");
    let s =
        std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {}: {}", path.display(), e));
    let v: serde_json::Value = serde_json::from_str(&s).expect("valid JSON");
    let rows = v["rows"].as_array().expect("rows array");
    assert!(rows.len() >= 15, "expected >=15 rows, got {}", rows.len());
    for (i, row) in rows.iter().enumerate() {
        for key in ["id", "principal", "action", "resource", "context", "expect"] {
            assert!(row.get(key).is_some(), "row {} missing {}", i, key);
        }
        let expect = row["expect"].as_str().unwrap();
        assert!(
            expect == "allow" || expect == "deny",
            "row {} expect must be allow|deny, got {}",
            i,
            expect
        );
    }
}

#[test]
fn cedar_rules_are_present() {
    let rules = repo_root().join("policy/rules");
    let mut count = 0;
    for entry in std::fs::read_dir(&rules).expect("read rules") {
        let p = entry.unwrap().path();
        if p.extension().and_then(|s| s.to_str()) == Some("cedar") {
            let body = std::fs::read_to_string(&p).unwrap();
            assert!(!body.trim().is_empty(), "empty rule {}", p.display());
            count += 1;
        }
    }
    assert!(count >= 4, "expected >=4 .cedar files, got {}", count);
}
