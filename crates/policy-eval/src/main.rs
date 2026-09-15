use anyhow::{anyhow, Context, Result};
use cedar_policy::{Authorizer, Decision, Entities, PolicySet, Request};
use std::path::{Path, PathBuf};

#[derive(serde::Deserialize)]
struct DecisionTable {
    rows: Vec<Row>,
}

#[derive(serde::Deserialize)]
struct Row {
    id: String,
    principal: String,
    action: String,
    resource: String,
    #[serde(default)]
    resource_path: Option<String>,
    #[serde(default)]
    context: serde_json::Value,
    expect: String,
}

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

fn load_policies(dir: &Path) -> Result<PolicySet> {
    // Load every .cedar file under policy/, including the top-level
    // principals.cedar, actions.cedar, resources.cedar — not just
    // policy/rules/. Missing any of them drops the permits and Cedar
    // fails closed.
    let mut combined = String::new();
    let mut files: Vec<PathBuf> = Vec::new();
    for entry in std::fs::read_dir(dir)? {
        let p = entry?.path();
        if p.extension().and_then(|s| s.to_str()) == Some("cedar") {
            files.push(p);
        }
    }
    if let Ok(rd) = std::fs::read_dir(dir.join("rules")) {
        for entry in rd {
            let p = entry?.path();
            if p.extension().and_then(|s| s.to_str()) == Some("cedar") {
                files.push(p);
            }
        }
    }
    files.sort();
    for f in &files {
        combined.push_str(&std::fs::read_to_string(f)?);
        combined.push('\n');
    }
    combined
        .parse::<PolicySet>()
        .map_err(|e| anyhow!("cedar parse error: {e}"))
}

fn build_request(row: &Row) -> Result<Request> {
    use cedar_policy::{Context, EntityUid};
    use std::str::FromStr;

    let principal = EntityUid::from_str(&format!("Principal::\"{}\"", row.principal))
        .map_err(|e| anyhow!("principal uid: {e}"))?;
    let action = EntityUid::from_str(&format!("Action::\"{}\"", row.action))
        .map_err(|e| anyhow!("action uid: {e}"))?;
    let resource = EntityUid::from_str(&format!("Resource::\"{}\"", row.resource))
        .map_err(|e| anyhow!("resource uid: {e}"))?;

    let mut ctx_val = if row.context.is_null() {
        serde_json::json!({})
    } else {
        row.context.clone()
    };
    if let Some(obj) = ctx_val.as_object_mut() {
        if let Some(path) = row.resource_path.as_ref() {
            obj.insert(
                "resource_path".into(),
                serde_json::Value::String(path.clone()),
            );
        }
    }
    let context = Context::from_json_value(ctx_val, None).map_err(|e| anyhow!("context: {e}"))?;

    Request::new(principal, action, resource, context, None).map_err(|e| anyhow!("request: {e}"))
}

fn main() -> Result<()> {
    let root = repo_root();
    let policy_dir = root.join("policy");
    let table_path = policy_dir.join("tests/decision-table.json");
    let policies =
        load_policies(&policy_dir).with_context(|| format!("loading {}", policy_dir.display()))?;
    let table: DecisionTable = serde_json::from_str(&std::fs::read_to_string(&table_path)?)?;
    let auth = Authorizer::new();
    let (mut pass, mut fail) = (0usize, 0usize);
    for row in &table.rows {
        let req = match build_request(row) {
            Ok(r) => r,
            Err(e) => {
                println!("  ERROR {:<40} {}", row.id, e);
                fail += 1;
                continue;
            }
        };
        let resp = auth.is_authorized(&req, &policies, &Entities::empty());
        let got = match resp.decision() {
            Decision::Allow => "allow",
            Decision::Deny => "deny",
        };
        if got == row.expect {
            println!("  ok    {:<40} {}", row.id, got);
            pass += 1;
        } else {
            println!("  FAIL  {:<40} want={} got={}", row.id, row.expect, got);
            fail += 1;
        }
    }
    println!("  {pass} passed, {fail} failed");
    if fail > 0 {
        std::process::exit(1);
    }
    Ok(())
}
