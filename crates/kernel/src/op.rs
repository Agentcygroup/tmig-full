//! Op: a first-class operation.

use crate::error::Error;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

/// The effect an op has on the world.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Effect {
    /// Reads state, does not mutate.
    Read,
    /// Mutates state within the sandbox.
    Write,
    /// Executes a process.
    Exec,
}

impl fmt::Display for Effect {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Effect::Read => f.write_str("read"),
            Effect::Write => f.write_str("write"),
            Effect::Exec => f.write_str("exec"),
        }
    }
}

impl FromStr for Effect {
    type Err = Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "read" => Ok(Effect::Read),
            "write" => Ok(Effect::Write),
            "exec" => Ok(Effect::Exec),
            other => Err(Error::Schema(format!("unknown effect `{other}`"))),
        }
    }
}

/// Op name.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct OpName(String);

impl OpName {
    /// The name as a string slice.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for OpName {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl FromStr for OpName {
    type Err = Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.is_empty() {
            return Err(Error::Schema("empty op name".into()));
        }
        if !s
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
        {
            return Err(Error::Schema(format!("bad op name `{s}`")));
        }
        Ok(Self(s.to_owned()))
    }
}

impl TryFrom<String> for OpName {
    type Error = Error;
    fn try_from(s: String) -> Result<Self, Self::Error> {
        s.parse()
    }
}

impl From<OpName> for String {
    fn from(n: OpName) -> Self {
        n.0
    }
}

/// A first-class operation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Op {
    /// Name.
    pub name: OpName,
    /// Effect.
    pub effect: Effect,
    /// Typed input names.
    pub inputs: Vec<String>,
    /// Typed output names.
    pub outputs: Vec<String>,
}

impl Op {
    /// Build a new op.
    pub fn new(
        name: &str,
        effect: Effect,
        inputs: Vec<String>,
        outputs: Vec<String>,
    ) -> Result<Self, Error> {
        Ok(Self {
            name: name.parse()?,
            effect,
            inputs,
            outputs,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn effect_roundtrip() {
        for e in [Effect::Read, Effect::Write, Effect::Exec] {
            let s = e.to_string();
            assert_eq!(s.parse::<Effect>().unwrap(), e);
        }
    }
    #[test]
    fn effect_rejects_unknown() {
        assert!("mutate".parse::<Effect>().is_err());
    }
    #[test]
    fn op_name_rejects_empty() {
        assert!("".parse::<OpName>().is_err());
    }
    #[test]
    fn op_serializes() {
        let op = Op::new(
            "detect",
            Effect::Read,
            vec!["image".into()],
            vec!["boxes".into()],
        )
        .unwrap();
        let s = serde_json::to_string(&op).unwrap();
        assert!(s.contains(r#""name":"detect""#));
        assert!(s.contains(r#""effect":"read""#));
    }
}
