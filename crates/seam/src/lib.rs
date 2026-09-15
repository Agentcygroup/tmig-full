//! seam — symmetric dispatch between open-set nodes.
//!
//! Shape:
//!   - `Node` is the one trait. Every participant implements it.
//!   - `NodeId` names a node. `Web` holds nodes by id.
//!   - `Node::call` lets a node call any other node, including one that
//!     calls it back. Edges have no preferred direction (toroidal).
//!   - `Web::register` grows the set at runtime. No trait change
//!     (orthogonal, unbounded).
//!   - Every `Message` carries a `nonclaim`. Empty is unrepresentable.
//!
//! Invariant: no `call` returns a `Message` without a nonclaim.

pub mod limits;
pub mod message;
pub mod node;
pub mod web;

pub use message::{Message, NonClaim};
pub use node::{Node, NodeId, SeamError};
pub use web::Web;
