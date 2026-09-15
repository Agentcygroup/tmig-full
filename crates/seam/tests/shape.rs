use seam::{Message, Node, NodeId, NonClaim, SeamError, Web};

fn nc(s: &str) -> NonClaim {
    NonClaim::new(s).unwrap()
}

/// A node that echoes and, if asked, calls back to a target.
struct Echo {
    id: NodeId,
    reply_to: Option<NodeId>,
    nonclaim: String,
}

impl Node for Echo {
    fn id(&self) -> NodeId {
        self.id.clone()
    }
    fn nonclaim(&self) -> &str {
        &self.nonclaim
    }

    fn handle(&self, msg: Message, web: &mut Web) -> Result<Message, SeamError> {
        let already_echoed = msg.body.get("echo").is_some();
        if !already_echoed {
            if let Some(target) = &self.reply_to {
                let out = Message::new(
                    self.id.clone(),
                    target.clone(),
                    serde_json::json!({ "echo": msg.body.clone() }),
                    msg.depth.saturating_sub(1),
                    nc(&self.nonclaim),
                );
                return web.call(out);
            }
        }
        Ok(Message::new(
            self.id.clone(),
            msg.from,
            msg.body,
            msg.depth,
            nc(&self.nonclaim),
        ))
    }
}

#[test]
fn toroidal_edge_cycles_and_terminates() {
    let mut web = Web::new();
    web.register(Box::new(Echo {
        id: NodeId::new("a"),
        reply_to: Some(NodeId::new("b")),
        nonclaim: "a is a demo node".to_string(),
    }));
    web.register(Box::new(Echo {
        id: NodeId::new("b"),
        reply_to: Some(NodeId::new("a")),
        nonclaim: "b is a demo node".to_string(),
    }));

    let msg = Message::new(
        NodeId::new("a"),
        NodeId::new("b"),
        serde_json::json!({ "ping": 1 }),
        4,
        nc("orchestrator"),
    );
    let out = web.call(msg).expect("cycle terminates");
    assert_eq!(out.nonclaim.as_str(), "a is a demo node");
}

#[test]
fn open_set_grows_at_runtime() {
    let mut web = Web::new();
    web.register(Box::new(Echo {
        id: NodeId::new("a"),
        reply_to: None,
        nonclaim: "a".to_string(),
    }));
    assert_eq!(web.ids().len(), 1);
    // Add the N+1th node. No trait change, no recompile of `a`.
    web.register(Box::new(Echo {
        id: NodeId::new("c"),
        reply_to: None,
        nonclaim: "c".to_string(),
    }));
    assert_eq!(web.ids().len(), 2);
    assert!(web.contains(&NodeId::new("c")));
}

#[test]
fn nonclaim_is_mandatory() {
    assert!(NonClaim::new("").is_none());
    assert!(NonClaim::new("   ").is_none());
    assert!(NonClaim::new("real").is_some());
}

#[test]
fn missing_node_errors() {
    let mut web = Web::new();
    web.register(Box::new(Echo {
        id: NodeId::new("a"),
        reply_to: None,
        nonclaim: "a".to_string(),
    }));
    let msg = Message::new(
        NodeId::new("a"),
        NodeId::new("ghost"),
        serde_json::json!({}),
        2,
        nc("test"),
    );
    assert!(matches!(
        web.call(msg).unwrap_err(),
        SeamError::NoSuchNode(_)
    ));
}

#[test]
fn depth_brake_stops_runaway_cycle() {
    // A node that ALWAYS re-calls, ignoring echo. This is the malformed
    // cycle the depth brake exists to catch.
    struct Loop {
        id: NodeId,
        target: NodeId,
        nonclaim: String,
    }
    impl Node for Loop {
        fn id(&self) -> NodeId {
            self.id.clone()
        }
        fn nonclaim(&self) -> &str {
            &self.nonclaim
        }
        fn handle(&self, msg: Message, web: &mut Web) -> Result<Message, SeamError> {
            let out = Message::new(
                self.id.clone(),
                self.target.clone(),
                msg.body.clone(),
                msg.depth.saturating_sub(1),
                nc(&self.nonclaim),
            );
            web.call(out)
        }
    }
    let mut web = Web::new();
    web.register(Box::new(Loop {
        id: NodeId::new("a"),
        target: NodeId::new("b"),
        nonclaim: "a".to_string(),
    }));
    web.register(Box::new(Loop {
        id: NodeId::new("b"),
        target: NodeId::new("a"),
        nonclaim: "b".to_string(),
    }));
    let msg = Message::new(
        NodeId::new("a"),
        NodeId::new("b"),
        serde_json::json!({}),
        3,
        nc("test"),
    );
    assert!(matches!(
        web.call(msg).unwrap_err(),
        SeamError::DepthExhausted(_)
    ));
}
