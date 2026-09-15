use crate::message::Message;

#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct NodeId(pub String);

impl NodeId {
    pub fn new(s: impl Into<String>) -> Self {
        Self(s.into())
    }
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, thiserror::Error)]
pub enum SeamError {
    #[error("no such node: {0}")]
    NoSuchNode(String),
    #[error("depth exhausted at {0}")]
    DepthExhausted(String),
    #[error("node error: {0}")]
    Node(String),
}

/// One trait, reflected many ways.
pub trait Node: Send + Sync {
    fn id(&self) -> NodeId;
    fn nonclaim(&self) -> &str;

    /// Handle an inbound message. May call `web.call(...)` back out.
    fn handle(&self, msg: Message, web: &mut crate::Web) -> Result<Message, SeamError>;
}
