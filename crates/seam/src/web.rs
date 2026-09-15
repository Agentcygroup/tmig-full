use crate::message::Message;
use crate::node::{Node, NodeId, SeamError};
use std::collections::BTreeMap;
use std::sync::Arc;

pub struct Web {
    nodes: BTreeMap<String, Arc<dyn Node>>,
}

impl Default for Web {
    fn default() -> Self {
        Self::new()
    }
}

impl Web {
    pub fn new() -> Self {
        Self {
            nodes: BTreeMap::new(),
        }
    }

    /// Open set: register any `Node` at any time.
    pub fn register(&mut self, node: Box<dyn Node>) {
        let id = node.id().0.clone();
        self.nodes.insert(id, Arc::from(node));
    }

    pub fn ids(&self) -> Vec<NodeId> {
        self.nodes.keys().cloned().map(NodeId).collect()
    }

    pub fn contains(&self, id: &NodeId) -> bool {
        self.nodes.contains_key(&id.0)
    }

    /// Toroidal dispatch: any node to any node. Cycles allowed; depth
    /// is the only brake. The target is cloned out of the map so the
    /// node remains registered during its own handler — this is what
    /// lets A -> B -> A terminate instead of failing with NoSuchNode.
    pub fn call(&mut self, msg: Message) -> Result<Message, SeamError> {
        if msg.depth == 0 {
            return Err(SeamError::DepthExhausted(msg.to.0));
        }
        let node = self
            .nodes
            .get(&msg.to.0)
            .cloned()
            .ok_or_else(|| SeamError::NoSuchNode(msg.to.0.clone()))?;
        node.handle(msg, self)
    }
}
