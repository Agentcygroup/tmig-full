//! The one definition of "a nonclaim."
//!
//! A nonclaim is a non-empty string that does not contain any of the
//! forbidden claim-words. Both properties are enforced at construction.
//!
//! Forbidden words mirror policy/rules/04-nonclaims.cedar. If that file
//! changes, this list changes with it. The two are checked against each
//! other by tests/forbidden_words_match_policy.rs.

use serde::{Deserialize, Serialize};

pub const FORBIDDEN_CLAIMS: &[&str] = &[
    "mastery",
    "accreditation",
    "coherence-proof",
    "completeness",
];

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct NonClaim(String);

#[derive(Debug, PartialEq)]
pub enum NonClaimError {
    Empty,
    Forbidden(String),
}

impl NonClaim {
    pub fn new(s: impl Into<String>) -> Result<Self, NonClaimError> {
        let s = s.into();
        if s.trim().is_empty() {
            return Err(NonClaimError::Empty);
        }
        let l = s.to_ascii_lowercase();
        for w in FORBIDDEN_CLAIMS {
            if l.contains(w) {
                return Err(NonClaimError::Forbidden((*w).into()));
            }
        }
        Ok(Self(s))
    }
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
