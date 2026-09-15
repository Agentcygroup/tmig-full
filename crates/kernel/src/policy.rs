//! cedar-policy integration.

use crate::error::{Error, Result};
use cedar_policy::{Authorizer, Context, Entities, PolicySet, Request};
use std::path::Path;
use std::str::FromStr;

/// Parsed cedar policy set with an authorizer.
pub struct Policy {
    set: PolicySet,
}

impl Policy {
    /// Load a `.cedar` file from disk.
    pub fn load(path: &Path) -> Result<Self> {
        let src = std::fs::read_to_string(path)?;
        Self::from_str(&src, path)
    }

    /// Parse a policy from a string.
    pub fn from_str(src: &str, origin: &Path) -> Result<Self> {
        let set = PolicySet::from_str(src).map_err(|e| Error::PolicyParse {
            path: origin.to_path_buf(),
            msg: e.to_string(),
        })?;
        Ok(Self { set })
    }

    /// Ask the policy whether an op may run.
    pub fn authorize(
        &self,
        principal_name: &str,
        action: &str,
        resource: &str,
        context: serde_json::Value,
    ) -> Result<String> {
        let principal = format!(r#"Principal::"{principal_name}""#)
            .parse()
            .map_err(|e: cedar_policy::ParseErrors| Error::Schema(e.to_string()))?;
        let action = format!(r#"Action::"{action}""#)
            .parse()
            .map_err(|e: cedar_policy::ParseErrors| Error::Schema(e.to_string()))?;
        let resource = format!(r#"Resource::"{resource}""#)
            .parse()
            .map_err(|e: cedar_policy::ParseErrors| Error::Schema(e.to_string()))?;
        let ctx =
            Context::from_json_value(context, None).map_err(|e| Error::Schema(e.to_string()))?;
        let req = Request::new(principal, action, resource, ctx, None)
            .map_err(|e| Error::Schema(e.to_string()))?;

        let entities = Entities::empty();
        let authorizer = Authorizer::new();
        let decision = authorizer.is_authorized(&req, &self.set, &entities);

        match decision.decision() {
            cedar_policy::Decision::Allow => Ok("allow".to_owned()),
            cedar_policy::Decision::Deny => {
                let reason = decision
                    .diagnostics()
                    .reason()
                    .next()
                    .map(|id| id.to_string())
                    .unwrap_or_else(|| "denied".to_owned());
                Err(Error::Denied {
                    op: "op".to_owned(),
                    reason,
                })
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    const SRC: &str = r#"
        @id("test.allow")
        permit (principal, action, resource)
        when { context.decision == "allow" };

        @id("test.deny")
        forbid (principal, action, resource)
        when { context.decision != "allow" };
    "#;

    #[test]
    fn allow_when_context_says_allow() {
        let p = Policy::from_str(SRC, &PathBuf::from("test.cedar")).unwrap();
        let r = p.authorize(
            "kernel",
            "detect",
            "image:1",
            serde_json::json!({"decision":"allow"}),
        );
        assert!(r.is_ok());
    }

    #[test]
    fn deny_when_context_says_deny() {
        let p = Policy::from_str(SRC, &PathBuf::from("test.cedar")).unwrap();
        let r = p.authorize(
            "kernel",
            "detect",
            "image:1",
            serde_json::json!({"decision":"deny"}),
        );
        assert!(matches!(r, Err(Error::Denied { .. })));
    }
}
