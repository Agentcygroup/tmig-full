//! Entity: a typed, addressable thing.

use crate::error::{Error, Result};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

/// A content-addressable entity id.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct EntityId(String);

impl EntityId {
    /// The id as a string slice.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for EntityId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl FromStr for EntityId {
    type Err = Error;
    fn from_str(s: &str) -> Result<Self> {
        if s.len() < 3 {
            return Err(Error::EntityId(s.to_owned()));
        }
        if s.chars().next().is_some_and(|c| c.is_ascii_digit()) {
            return Err(Error::EntityId(s.to_owned()));
        }
        for c in s.chars() {
            if !(c.is_ascii_lowercase() || c.is_ascii_digit() || matches!(c, ':' | '-' | '_')) {
                return Err(Error::EntityId(s.to_owned()));
            }
        }
        Ok(Self(s.to_owned()))
    }
}

impl TryFrom<String> for EntityId {
    type Error = Error;
    fn try_from(s: String) -> Result<Self> {
        s.parse()
    }
}

impl From<EntityId> for String {
    fn from(id: EntityId) -> Self {
        id.0
    }
}

/// Entity kind discriminator.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct EntityKind(String);

impl EntityKind {
    /// The kind as a string slice.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for EntityKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl FromStr for EntityKind {
    type Err = Error;
    fn from_str(s: &str) -> Result<Self> {
        if s.len() < 2
            || !s
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
        {
            return Err(Error::EntityId(s.to_owned()));
        }
        Ok(Self(s.to_owned()))
    }
}

impl TryFrom<String> for EntityKind {
    type Error = Error;
    fn try_from(s: String) -> Result<Self> {
        s.parse()
    }
}

impl From<EntityKind> for String {
    fn from(k: EntityKind) -> Self {
        k.0
    }
}

/// A typed, addressable thing.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Entity {
    /// Content-addressed id.
    pub id: EntityId,
    /// Kind discriminator.
    pub kind: EntityKind,
    /// Free-form attributes.
    #[serde(default, skip_serializing_if = "serde_json::Value::is_null")]
    pub attrs: serde_json::Value,
}

impl Entity {
    /// Build a new entity. Fails if id or kind is malformed.
    pub fn new(id: &str, kind: &str, attrs: serde_json::Value) -> Result<Self> {
        Ok(Self {
            id: id.parse()?,
            kind: kind.parse()?,
            attrs,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_id() {
        let id: EntityId = "image:1".parse().unwrap();
        assert_eq!(id.as_str(), "image:1");
    }
    #[test]
    fn rejects_short() {
        assert!("ab".parse::<EntityId>().is_err());
    }
    #[test]
    fn rejects_leading_digit() {
        assert!("1image".parse::<EntityId>().is_err());
    }
    #[test]
    fn rejects_uppercase() {
        assert!("Image:1".parse::<EntityId>().is_err());
    }
    #[test]
    fn entity_roundtrip() {
        let e = Entity::new("doc:1", "document", serde_json::json!({"lang":"en"})).unwrap();
        let s = serde_json::to_string(&e).unwrap();
        let back: Entity = serde_json::from_str(&s).unwrap();
        assert_eq!(e, back);
    }
    #[test]
    fn kind_min_length() {
        assert!("a".parse::<EntityKind>().is_err());
        assert!("ab".parse::<EntityKind>().is_ok());
    }
}
