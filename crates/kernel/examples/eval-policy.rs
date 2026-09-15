//! Evaluate policy/tests/decision-table.json against the policy tree.
//!
//! Used by policy/run-tests.sh when the Cedar CLI is not installed.
//! Loads the concatenated policy sources, then for each row of the
//! decision table, asks the Constitution to authorize the op. Compares
//! the decision to the row's `expect` field. Exits 0 iff all match.

use kernel::{Constitution, EntityId, Effect, Error, Op};
use std::path::{Path, PathBuf};
use std::str::FromStr;

fn collect_cedar(dir: &Path) -> Result<String, Error> {
    let mut out = String::new();
    let mut stack = vec![dir.to_path_buf()];
    while let Some(d) = stack.pop() {
        for entry in std::fs::read_dir(&d)? {
            let e = entry?;
            let p = e.path();
            if p.is_dir() {
                stack.push(p);
            } else if p.extension().map(|x| x == "cedar").unwrap_or(false) {
                out.push_str(&std::fs::read_to_string(&p)?);
                out.push('\n');
            }
        }
    }
    Ok(out)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let root = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "policy".to_string());
    let policy_dir = PathBuf::from(&root);

    // Concatenate every .cedar in the tree, then write it to a temp
    // file so Constitution::load can read it in one pass. This mirrors
    // what crates/policy does for policies/*.cedar.
    let combined = collect_cedar(&policy_dir)?;
    let tmp = std::env::temp_dir().join(format!("kernel-policy-{}.cedar", std::process::id()));
    std::fs::write(&tmp, &combined)?;

    let constitution = match Constitution::load(&tmp) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("constitution load failed: {e}");
            std::process::exit(1);
        }
    };

    let table_str = std::fs::read_to_string(policy_dir.join("tests/decision-table.json"))?;
    let table: serde_json::Value = serde_json::from_str(&table_str)?;

    let mut pass = 0usize;
    let mut fail = 0usize;

    for row in table["rows"].as_array().cloned().unwrap_or_default() {
        let id = row["id"].as_str().unwrap_or("?");
        let action = row["action"].as_str().unwrap_or("read");
        let resource = row["resource"].as_str().unwrap_or("res:1");
        let ctx = row["context"].clone();
        let expect = row["expect"].as_str().unwrap_or("deny");

        let op = match Op::new(action, Effect::Read, vec![], vec![]) {
            Ok(o) => o,
            Err(e) => {
                println!("  FAIL  {id:<32} op build: {e}");
                fail += 1;
                continue;
            }
        };
        let target: EntityId = match EntityId::from_str(resource) {
            Ok(t) => t,
            Err(e) => {
                println!("  FAIL  {id:<32} resource: {e}");
                fail += 1;
                continue;
            }
        };

        let got = match constitution.authorize(&op, &target, ctx) {
            Ok(r) if r.verify() => "allow",
            _ => "deny",
        };

        if got == expect {
            println!("  ok    {id:<32} {got}");
            pass += 1;
        } else {
            println!("  FAIL  {id:<32} got={got} want={expect}");
            fail += 1;
        }
    }

    let _ = std::fs::remove_file(&tmp);

    println!("  {pass} passed, {fail} failed");
    if fail == 0 { Ok(()) } else { std::process::exit(1) }
}
