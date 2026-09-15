use cedar_policy::{Authorizer, Context, Entities, PolicySet, Request, Schema};
use serde::Deserialize;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PolicyError {
    #[error("policy file not found: {0}")]
    NotFound(PathBuf),
    #[error("cedar parse error in {file}: {msg}")]
    Parse { file: PathBuf, msg: String },
    #[error("schema error: {0}")]
    Schema(String),
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
}

pub struct PolicySetBundle {
    pub policies: PolicySet,
    pub schema: Option<Schema>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct Violation {
    pub policy_id: String,
    pub reason: String,
}

pub fn load(dir: &Path) -> Result<PolicySetBundle, PolicyError> {
    let schema_path = dir.join("schema.json");
    let schema = if schema_path.exists() {
        let src = std::fs::read_to_string(&schema_path)?;
        Some(Schema::from_json_str(&src).map_err(|e| PolicyError::Schema(e.to_string()))?)
    } else {
        None
    };

    let mut policies = PolicySet::new();
    let mut entries: Vec<_> = std::fs::read_dir(dir)?
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map(|x| x == "cedar").unwrap_or(false))
        .collect();
    entries.sort_by_key(|e| e.path());

    for e in entries {
        let p = e.path();
        let src = std::fs::read_to_string(&p)?;
        let parsed = PolicySet::from_str(&src).map_err(|err| PolicyError::Parse {
            file: p.clone(),
            msg: err.to_string(),
        })?;
        // cedar-policy 4.12: merge mutates self in place and returns
        // Result<HashMap<PolicyId, PolicyId>, PolicySetError>.
        let collisions = policies
            .merge(&parsed, true)
            .map_err(|err| PolicyError::Parse {
                file: p.clone(),
                msg: err.to_string(),
            })?;
        if !collisions.is_empty() {
            eprintln!(
                "policy id collisions auto-renamed: {} in {}",
                collisions.len(),
                p.display()
            );
        }
    }

    Ok(PolicySetBundle { policies, schema })
}

pub fn request_for(
    layer: &str,
    layer_strength: u32,
    target_id: &str,
    target_kind: &str,
    target_cmd: Option<&str>,
) -> Result<Request, PolicyError> {
    let principal = r#"Principal::"xt""#;
    let action = format!(r#"Action::"{}""#, target_kind);
    let resource = format!(r#"Resource::"{}""#, target_id);
    let context_json = serde_json::json!({
        "layer": layer,
        "strength": layer_strength,
        "cmd": target_cmd.unwrap_or(""),
    })
    .to_string();

    let p = principal
        .parse()
        .map_err(|e: cedar_policy::ParseErrors| PolicyError::Schema(e.to_string()))?;
    let a = action
        .parse()
        .map_err(|e: cedar_policy::ParseErrors| PolicyError::Schema(e.to_string()))?;
    let r = resource
        .parse()
        .map_err(|e: cedar_policy::ParseErrors| PolicyError::Schema(e.to_string()))?;
    let ctx = Context::from_json_str(&context_json, None)
        .map_err(|e| PolicyError::Schema(e.to_string()))?;

    Request::new(p, a, r, ctx, None).map_err(|e| PolicyError::Schema(e.to_string()))
}

pub fn check(bundle: &PolicySetBundle, requests: &[Request]) -> Result<(), Vec<Violation>> {
    let authorizer = Authorizer::new();
    let entities = Entities::empty();
    let mut violations = Vec::new();

    for req in requests {
        let decision = authorizer.is_authorized(req, &bundle.policies, &entities);
        if !matches!(decision.decision(), cedar_policy::Decision::Allow) {
            let reason = decision
                .diagnostics()
                .reason()
                .next()
                .map(|id| id.to_string())
                .unwrap_or_else(|| "denied".to_string());
            let id = reason
                .split_whitespace()
                .next()
                .unwrap_or("policy")
                .to_string();
            violations.push(Violation {
                policy_id: id,
                reason,
            });
        }
    }

    if violations.is_empty() {
        Ok(())
    } else {
        Err(violations)
    }
}
