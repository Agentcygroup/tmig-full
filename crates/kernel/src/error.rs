//! Kernel error type.

use std::path::PathBuf;

/// Errors that the kernel surfaces.
#[derive(Debug, thiserror::Error)]
pub enum Error {
    /// A policy file could not be read.
    #[error("policy read failed: {0}")]
    PolicyRead(#[from] std::io::Error),
    /// Cedar rejected a policy file.
    #[error("policy parse failed in {path}: {msg}")]
    PolicyParse {
        /// Path of the failing file.
        path: PathBuf,
        /// Cedar's error message.
        msg: String,
    },
    /// Cedar denied the request.
    #[error("op `{op}` denied by policy: {reason}")]
    Denied {
        /// The op that was denied.
        op: String,
        /// Why the policy said no.
        reason: String,
    },
    /// A JSON schema failed to deserialize.
    #[error("schema failed: {0}")]
    Schema(String),
    /// Lineage is not acyclic.
    #[error("lineage cycle at entity `{0}`")]
    LineageCycle(String),
    /// Entity id is malformed.
    #[error("entity id malformed: `{0}`")]
    EntityId(String),
}

/// Convenience alias.
pub type Result<T> = std::result::Result<T, Error>;
