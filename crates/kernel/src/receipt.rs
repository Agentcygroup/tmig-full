//! Receipt: the signed record of an Op that ran.

use crate::entity::EntityId;
use crate::op::OpName;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::time::{SystemTime, UNIX_EPOCH};

/// Record of an op that ran.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Receipt {
    /// Op that ran.
    pub op: OpName,
    /// Input entity ids.
    pub inputs: Vec<EntityId>,
    /// Output entity ids.
    pub outputs: Vec<EntityId>,
    /// Cedar's reason string for the allow decision.
    pub decision: String,
    /// Unix seconds at the moment the receipt was written.
    pub ts: u64,
    /// SHA-256 over the canonical JSON of everything except `hash`.
    pub hash: String,
}

impl Receipt {
    /// Build a receipt and compute its hash.
    pub fn new(
        op: OpName,
        inputs: Vec<EntityId>,
        outputs: Vec<EntityId>,
        decision: String,
    ) -> Self {
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);
        let mut r = Self {
            op,
            inputs,
            outputs,
            decision,
            ts,
            hash: String::new(),
        };
        r.hash = r.compute_hash();
        r
    }

    fn compute_hash(&self) -> String {
        let canonical = serde_json::json!({
            "op":       self.op.as_str(),
            "inputs":   self.inputs.iter().map(|i| i.as_str()).collect::<Vec<_>>(),
            "outputs":  self.outputs.iter().map(|o| o.as_str()).collect::<Vec<_>>(),
            "decision": self.decision,
            "ts":       self.ts,
        });
        let bytes = serde_json::to_vec(&canonical).unwrap_or_default();
        hex::encode(Sha256::digest(&bytes))
    }

    /// Verify that `hash` matches the receipt's other fields.
    #[must_use]
    pub fn verify(&self) -> bool {
        self.compute_hash() == self.hash
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_is_stable() {
        let r = Receipt::new(
            "detect".parse().unwrap(),
            vec!["image:1".parse().unwrap()],
            vec!["bbox:1".parse().unwrap()],
            "allow".into(),
        );
        assert!(r.verify());
    }
    #[test]
    fn tamper_detected() {
        let mut r = Receipt::new(
            "detect".parse().unwrap(),
            vec!["image:1".parse().unwrap()],
            vec!["bbox:1".parse().unwrap()],
            "allow".into(),
        );
        r.decision = "deny".into();
        assert!(!r.verify());
    }
    #[test]
    fn roundtrip_json() {
        let r = Receipt::new(
            "segment".parse().unwrap(),
            vec!["image:1".parse().unwrap()],
            vec!["mask:1".parse().unwrap()],
            "allow".into(),
        );
        let s = serde_json::to_string(&r).unwrap();
        let back: Receipt = serde_json::from_str(&s).unwrap();
        assert!(back.verify());
        assert_eq!(r, back);
    }
}
