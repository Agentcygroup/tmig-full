//! Bounds for recursive and unbounded structures. Every recursion in
//! `seam` is bounded by one of these; changing them is a policy change.
pub const MAX_DEPTH: u32 = 64;
pub const MAX_BODY_BYTES: usize = 1 << 20; // 1 MiB
