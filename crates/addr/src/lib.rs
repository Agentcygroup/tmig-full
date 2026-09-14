use sha2::{Digest, Sha256};
use std::io::Read;
use std::path::Path;
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
pub struct Id(pub [u8; 32]);
impl Id {
    pub fn of(b: &[u8]) -> Self {
        let mut h = Sha256::new();
        h.update(b);
        Id(h.finalize().into())
    }
    pub fn of_dir(p: &Path) -> std::io::Result<Self> {
        let mut h = Sha256::new();
        let mut es: Vec<_> = walkdir::WalkDir::new(p)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().is_file())
            .collect();
        es.sort_by_key(|e| e.path().to_path_buf());
        for e in es {
            h.update(e.path().to_string_lossy().as_bytes());
            h.update(b"\0");
            let mut f = std::fs::File::open(e.path())?;
            let mut b = [0u8; 65536];
            loop {
                let n = f.read(&mut b)?;
                if n == 0 {
                    break;
                }
                h.update(&b[..n]);
            }
        }
        Ok(Id(h.finalize().into()))
    }
    pub fn hex(&self) -> String {
        let mut s = String::with_capacity(64);
        for b in self.0 {
            use std::fmt::Write;
            let _ = write!(s, "{b:02x}");
        }
        s
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn stable() {
        assert_eq!(Id::of(b"a"), Id::of(b"a"));
    }
}
