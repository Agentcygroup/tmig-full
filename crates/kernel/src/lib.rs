#![deny(warnings)]
#![deny(missing_docs)]
#![deny(rust_2018_idioms)]
#![deny(unreachable_pub)]
//! Constitutional Kernel.
//!
//! Five concepts. Every conforming extension shares them:
//!
//! - [`Entity`] — a typed, addressable thing
//! - [`Op`] — a first-class operation
//! - [`Lineage`] — the graph of what produced what
//! - [`Receipt`] — the signed record of an Op that ran
//! - [`Constitution`] — the policy that gates every Op

pub mod constitution;
pub mod entity;
pub mod error;
pub mod lineage;
pub mod op;
pub mod policy;
pub mod receipt;

pub use constitution::Constitution;
pub use entity::{Entity, EntityId, EntityKind};
pub use error::{Error, Result};
pub use lineage::Lineage;
pub use op::{Effect, Op, OpName};
pub use receipt::Receipt;
