use sha2::{Digest, Sha256};
use std::io::Write;
use std::path::{Path, PathBuf};

pub struct HermeticEnv {
    pub repo: PathBuf,
    pub out: PathBuf,
    pub freeze_digest: String,
    pub commit: String,
    pub toolchain_hash: String,
}

impl HermeticEnv {
    pub fn capture(repo: &Path, out: &Path) -> std::io::Result<Self> {
        let freeze = repo.join("xt.toml");
        let freeze_digest = digest_file(&freeze)?;
        let commit = run_capture(repo, "git", &["rev-parse", "HEAD"])?;
        let toolchain_hash = toolchain_hash()?;
        Ok(Self {
            repo: repo.to_path_buf(),
            out: out.to_path_buf(),
            freeze_digest,
            commit,
            toolchain_hash,
        })
    }

    pub fn tarball(&self, src: &Path) -> std::io::Result<PathBuf> {
        std::fs::create_dir_all(&self.out)?;
        let name = format!("xt-{}.tar.gz", &self.commit[..12.min(self.commit.len())]);
        let path = self.out.join(&name);

        let file = std::fs::File::create(&path)?;
        let gz = flate2::write::GzEncoder::new(file, flate2::Compression::best());
        let mut tar = tar::Builder::new(gz);
        tar.mode(tar::HeaderMode::Deterministic);

        let mut entries: Vec<PathBuf> = walkdir::WalkDir::new(src)
            .into_iter()
            .filter_entry(|e| {
                let n = e.file_name().to_string_lossy();
                !matches!(
                    n.as_ref(),
                    "target"
                        | "venvs"
                        | "venvs-graph"
                        | "tool-venvs"
                        | "oss-providers"
                        | "out"
                        | ".git"
                        | "taxonomy"
                        | "copyleft"
                        | "tools"
                        | "receipts"
                        | "node_modules"
                )
            })
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().is_file())
            .map(|e| e.path().to_path_buf())
            .collect();
        entries.sort();

        for entry in &entries {
            let rel = entry.strip_prefix(src).unwrap_or(entry);
            let meta = std::fs::metadata(entry)?;
            let mut h = tar::Header::new_gnu();
            h.set_size(meta.len());
            h.set_mode(0o644);
            h.set_uid(0);
            h.set_gid(0);
            h.set_mtime(0);
            h.set_cksum();
            let f = std::fs::File::open(entry)?;
            tar.append_data(&mut h, rel, f)?;
        }

        let manifest = serde_json::json!({
            "freeze_digest": self.freeze_digest,
            "commit": self.commit,
            "toolchain_hash": self.toolchain_hash,
            "files": entries.len(),
        });
        let mbytes = serde_json::to_vec_pretty(&manifest)?;
        let mut h = tar::Header::new_gnu();
        h.set_size(mbytes.len() as u64);
        h.set_mode(0o644);
        h.set_uid(0);
        h.set_gid(0);
        h.set_mtime(0);
        h.set_cksum();
        tar.append_data(&mut h, "MANIFEST.json", mbytes.as_slice())?;

        tar.finish()?;
        let gz = tar.into_inner()?;
        gz.finish()?;

        let tarball_digest = digest_file(&path)?;
        let mut sidecar = std::fs::File::create(self.out.join(format!("{name}.sha256")))?;
        writeln!(sidecar, "{}  {}", tarball_digest, name)?;
        Ok(path)
    }
}

fn digest_file(p: &Path) -> std::io::Result<String> {
    let mut h = Sha256::new();
    let mut f = std::fs::File::open(p)?;
    std::io::copy(&mut f, &mut h)?;
    Ok(hex::encode(h.finalize()))
}

fn run_capture(cwd: &Path, cmd: &str, args: &[&str]) -> std::io::Result<String> {
    let out = std::process::Command::new(cmd)
        .args(args)
        .current_dir(cwd)
        .output()?;
    if !out.status.success() {
        return Err(std::io::Error::other(format!("{cmd} failed")));
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

fn toolchain_hash() -> std::io::Result<String> {
    let mut h = Sha256::new();
    for (cmd, args) in [
        ("rustc", vec!["--version"]),
        ("cargo", vec!["--version"]),
        ("python3", vec!["--version"]),
    ] {
        if let Ok(o) = std::process::Command::new(cmd).args(&args).output() {
            h.update(&o.stdout);
        }
    }
    Ok(hex::encode(h.finalize()))
}
