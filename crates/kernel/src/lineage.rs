//! Lineage: the graph of what produced what.

use crate::entity::EntityId;
use crate::error::{Error, Result};
use std::collections::{HashMap, HashSet};

/// The parent-of relation between entities.
#[derive(Debug, Default, Clone)]
pub struct Lineage {
    parent: HashMap<EntityId, EntityId>,
}

impl Lineage {
    /// Empty lineage.
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Record that `child` was produced from `parent`.
    pub fn add(&mut self, parent: EntityId, child: EntityId) -> Result<()> {
        if parent == child {
            return Err(Error::LineageCycle(child.to_string()));
        }
        if let Some(existing) = self.parent.get(&child) {
            if existing != &parent {
                return Err(Error::LineageCycle(child.to_string()));
            }
            return Ok(());
        }
        let mut seen = HashSet::new();
        let mut cur = Some(&parent);
        while let Some(id) = cur {
            if !seen.insert(id.clone()) {
                break;
            }
            if id == &child {
                return Err(Error::LineageCycle(child.to_string()));
            }
            cur = self.parent.get(id);
        }
        self.parent.insert(child, parent);
        Ok(())
    }

    /// The parent of an entity, if any.
    #[must_use]
    pub fn parent_of(&self, child: &EntityId) -> Option<&EntityId> {
        self.parent.get(child)
    }

    /// Every ancestor of an entity, oldest last.
    #[must_use]
    pub fn ancestors_of(&self, child: &EntityId) -> Vec<EntityId> {
        let mut out = Vec::new();
        let mut cur = self.parent.get(child);
        let mut guard = HashSet::new();
        while let Some(id) = cur {
            if !guard.insert(id.clone()) {
                break;
            }
            out.push(id.clone());
            cur = self.parent.get(id);
        }
        out
    }

    /// Number of edges.
    #[must_use]
    pub fn len(&self) -> usize {
        self.parent.len()
    }

    /// True if empty.
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.parent.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id(s: &str) -> EntityId {
        s.parse().unwrap()
    }

    #[test]
    fn linear_chain() {
        let mut l = Lineage::new();
        l.add(id("root:1"), id("mid:1")).unwrap();
        l.add(id("mid:1"), id("leaf:1")).unwrap();
        assert_eq!(
            l.ancestors_of(&id("leaf:1")),
            vec![id("mid:1"), id("root:1")]
        );
    }
    #[test]
    fn cycle_rejected() {
        let mut l = Lineage::new();
        l.add(id("a:1"), id("b:1")).unwrap();
        assert!(l.add(id("b:1"), id("a:1")).is_err());
    }
    #[test]
    fn self_loop_rejected() {
        let mut l = Lineage::new();
        assert!(l.add(id("a:1"), id("a:1")).is_err());
    }
    #[test]
    fn duplicate_edge_is_ok() {
        let mut l = Lineage::new();
        l.add(id("a:1"), id("b:1")).unwrap();
        l.add(id("a:1"), id("b:1")).unwrap();
        assert_eq!(l.len(), 1);
    }
    #[test]
    fn conflicting_parent_rejected() {
        let mut l = Lineage::new();
        l.add(id("a:1"), id("c:1")).unwrap();
        assert!(l.add(id("b:1"), id("c:1")).is_err());
    }
}
