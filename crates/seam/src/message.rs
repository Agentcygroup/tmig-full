use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct NonClaim(String);

impl NonClaim {
    pub fn new(s: impl Into<String>) -> Option<Self> {
        let s = s.into();
        if s.trim().is_empty() {
            None
        } else {
            Some(Self(s))
        }
    }
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

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
        Self {
            from,
            to,
            body,
            depth,
            nonclaim,
        }
    }
}
