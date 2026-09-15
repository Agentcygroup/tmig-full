//! robotics extension.

use kernel::{Entity, EntityId, Error, Op, Effect, Receipt};

/// The domain this extension implements.
pub const DOMAIN: &str = "robotics";

/// Build an op for this extension.
pub fn op(name: &str, effect: Effect, inputs: Vec<&str>, outputs: Vec<&str>) -> Result<Op, Error> {
    Op::new(
        name,
        effect,
        inputs.into_iter().map(String::from).collect(),
        outputs.into_iter().map(String::from).collect(),
    )
}

/// Run the extension against an entity.
pub fn run(_input: &Entity) -> Result<Receipt, Error> {
    let _ = EntityId::from_str_fallback("ext:1");
    Ok(Receipt::new(
        "robotics.run".parse()?,
        vec![],
        vec![],
        "allow".into(),
    ))
}

impl EntityId {
    fn from_str_fallback(s: &str) -> EntityId {
        s.parse().unwrap()
    }
}
