pub use nonclaim::NonClaim;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Message {
    pub from: super::NodeId,
    pub to: super::NodeId,
    pub body: serde_json::Value,
    pub depth: u32,
    pub nonclaim: NonClaim,
}

impl Message {
    pub fn new(
        from: super::NodeId,
        to: super::NodeId,
        body: serde_json::Value,
        depth: u32,
        nonclaim: NonClaim,
    ) -> Self {
        assert!(
            depth <= crate::limits::MAX_DEPTH,
            "depth {} exceeds MAX_DEPTH {}",
            depth,
            crate::limits::MAX_DEPTH
        );
        let bytes = serde_json::to_vec(&body).map(|v| v.len()).unwrap_or(0);
        assert!(
            bytes <= crate::limits::MAX_BODY_BYTES,
            "body {} bytes exceeds MAX_BODY_BYTES {}",
            bytes,
            crate::limits::MAX_BODY_BYTES
        );
        Self {
            from,
            to,
            body,
            depth,
            nonclaim,
        }
    }
}
