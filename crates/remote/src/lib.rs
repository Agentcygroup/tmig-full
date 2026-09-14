use std::path::{Path, PathBuf};
pub struct Remote {
    pub root: PathBuf,
}
impl Remote {
    pub fn open(root: &Path) -> std::io::Result<Self> {
        std::fs::create_dir_all(root)?;
        Ok(Self {
            root: root.to_path_buf(),
        })
    }
    pub fn get(&self, k: &str) -> Option<String> {
        std::fs::read_to_string(self.root.join(format!("{k}.id")))
            .ok()
            .map(|s| s.trim().to_string())
    }
    pub fn put(&self, k: &str, v: &str) -> std::io::Result<()> {
        std::fs::write(self.root.join(format!("{k}.id")), v)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn put_get() {
        let tmp = std::env::temp_dir().join(format!("rem-{}", std::process::id()));
        let r = Remote::open(&tmp).unwrap();
        r.put("a", "b").unwrap();
        assert_eq!(r.get("a").as_deref(), Some("b"));
    }
}
