use serde::Deserialize;
use std::collections::BTreeMap;
#[derive(Debug, Clone, Deserialize)]
pub struct PolicyFile {
    pub layer: Vec<PolicyLayer>,
}
#[derive(Debug, Clone, Deserialize)]
pub struct PolicyLayer {
    pub id: String,
    pub strength: u32,
}
pub fn load(path: &std::path::Path) -> std::io::Result<BTreeMap<String, u32>> {
    let f: PolicyFile = toml::from_str(&std::fs::read_to_string(path)?)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e.to_string()))?;
    Ok(f.layer.into_iter().map(|l| (l.id, l.strength)).collect())
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn loads() {
        let tmp = std::env::temp_dir().join("pol-test.toml");
        std::fs::write(&tmp, "[[layer]]\nid=\"a\"\nstrength=10\n").unwrap();
        assert_eq!(load(&tmp).unwrap().get("a"), Some(&10));
    }
}
