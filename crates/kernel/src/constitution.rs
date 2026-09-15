//! Constitution: the policy that gates every Op.

use crate::entity::EntityId;
use crate::error::Result;
use crate::op::Op;
use crate::policy::Policy;
use crate::receipt::Receipt;
use std::path::{Path, PathBuf};

/// The policy set that governs all ops in the kernel.
pub struct Constitution {
    policy: Policy,
    origin: PathBuf,
}

impl Constitution {
    /// Load the constitution from a `.cedar` file.
    pub fn load(path: &Path) -> Result<Self> {
        let policy = Policy::load(path)?;
        Ok(Self {
            policy,
            origin: path.to_path_buf(),
        })
    }

    /// Where the constitution came from.
    #[must_use]
    pub fn origin(&self) -> &Path {
        &self.origin
    }

    /// Authorize an op against an entity.
    pub fn authorize(
        &self,
        principal_name: &str,
        op: &Op,
        target: &EntityId,
        context: serde_json::Value,
    ) -> Result<Receipt> {
        let decision =
            self.policy
                .authorize(principal_name, op.name.as_str(), target.as_str(), context)?;
        Ok(Receipt::new(
            op.name.clone(),
            vec![target.clone()],
            vec![],
            decision,
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::op::Effect;

    const SRC: &str = r#"
        @id("test.allow")
        permit (principal, action, resource)
        when { context.decision == "allow" };
    "#;

    #[test]
    fn authorize_builds_receipt() {
        let p = Policy::from_str(SRC, &PathBuf::from("t.cedar")).unwrap();
        let c = Constitution {
            policy: p,
            origin: PathBuf::from("t.cedar"),
        };
        let op = Op::new(
            "detect",
            Effect::Read,
            vec!["image".into()],
            vec!["boxes".into()],
        )
        .unwrap();
        let target: EntityId = "image:1".parse().unwrap();
        let r = c
            .authorize(
                "kernel",
                &op,
                &target,
                serde_json::json!({"decision":"allow"}),
            )
            .unwrap();
        assert!(r.verify());
        assert_eq!(r.op.as_str(), "detect");
    }
}
