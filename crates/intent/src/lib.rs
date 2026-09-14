pub mod producers;
use layer::{Layer, LayerFile, Resolved, Target};
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
pub struct Intent {
    pub repo: PathBuf,
    pub layers: Vec<(String, Layer)>,
}
#[derive(Debug, Default)]
pub struct Receipt {
    pub run_id: String,
    pub targets: Vec<Tr>,
    pub non_claims: Vec<String>,
}
#[derive(Debug)]
pub struct Tr {
    pub id: String,
    pub status: String,
    pub input_id: String,
    pub output_id: String,
}
pub fn load(repo: &Path) -> std::io::Result<Intent> {
    let mut layers = Vec::new();
    let m: LayerFile = toml::from_str(&std::fs::read_to_string(repo.join("xt.toml"))?)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e.to_string()))?;
    for (id, l) in m.layers {
        layers.push((id, l));
    }
    let xd = repo.join("xt.d");
    if xd.is_dir() {
        let mut fs: Vec<_> = std::fs::read_dir(&xd)?
            .filter_map(|e| e.ok())
            .filter(|e| e.path().extension().map(|x| x == "toml").unwrap_or(false))
            .collect();
        fs.sort_by_key(|e| e.path());
        for f in fs {
            let lf: LayerFile = toml::from_str(&std::fs::read_to_string(f.path())?)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e.to_string()))?;
            for (id, l) in lf.layers {
                layers.push((id, l));
            }
        }
    }
    if let Some(pd) = std::env::var("HOME")
        .ok()
        .map(|h| PathBuf::from(h).join("intent").join("producers"))
    {
        let prods = producers::load_all(&pd);
        let targets = producers::expand(repo, &prods);
        if !targets.is_empty() {
            layers.push((
                "produced".to_string(),
                Layer {
                    strength: 15,
                    targets,
                },
            ));
        }
    }
    Ok(Intent {
        repo: repo.to_path_buf(),
        layers,
    })
}
impl Intent {
    pub fn resolve(&self) -> Resolved {
        layer::resolve(&self.layers)
    }
    pub fn run(&self, t: &str) -> std::io::Result<Receipt> {
        let r = self.resolve();
        let mut rec = Receipt::default();
        let mut done = BTreeMap::new();
        let cache = self.repo.join("target").join("xt-cache");
        std::fs::create_dir_all(&cache)?;
        let rroot = std::env::var("XT_REMOTE")
            .ok()
            .map(PathBuf::from)
            .unwrap_or_else(|| self.repo.join("target").join("xt-remote"));
        let remote = remote::Remote::open(&rroot)?;
        self.run_one(t, &r, &mut done, &mut rec, &cache, &remote)?;
        rec.run_id = addr::Id::of(
            rec.targets
                .iter()
                .map(|x| x.output_id.as_str())
                .collect::<Vec<_>>()
                .join("|")
                .as_bytes(),
        )
        .hex();
        rec.non_claims = vec![
            "no-mastery".into(),
            "no-accreditation".into(),
            "no-coherence-proof".into(),
            "no-completeness".into(),
        ];
        std::fs::create_dir_all(self.repo.join("receipts"))?;
        std::fs::write(
            self.repo
                .join("receipts")
                .join(format!("{}.json", rec.run_id)),
            format!("{:#?}", rec),
        )?;
        Ok(rec)
    }
    fn run_one(
        &self,
        id: &str,
        r: &Resolved,
        done: &mut BTreeMap<String, String>,
        rec: &mut Receipt,
        cache: &Path,
        remote: &remote::Remote,
    ) -> std::io::Result<()> {
        if done.contains_key(id) {
            return Ok(());
        }
        let (_, t) = r.targets.get(id).ok_or_else(|| {
            std::io::Error::new(std::io::ErrorKind::NotFound, format!("no target {id}"))
        })?;
        for n in &t.needs {
            self.run_one(n, r, done, rec, cache, remote)?;
        }
        let iid = match t.kind.as_str() {
            "checks" => {
                let d = self.repo.join(t.dir.as_deref().unwrap_or("checks"));
                addr::Id::of_dir(&d).map(|i| i.hex()).unwrap_or_default()
            }
            _ => addr::Id::of(format!("{:?}", t).as_bytes()).hex(),
        };
        let cacheable = (t.kind == "shell" || t.kind == "checks") && !t.optional;
        if cacheable {
            let p = cache.join(format!("{iid}.json"));
            if p.exists() {
                if let Ok(txt) = std::fs::read_to_string(&p) {
                    if let Some(oid) = txt.lines().nth(1) {
                        done.insert(id.into(), oid.into());
                        rec.targets.push(Tr {
                            id: id.into(),
                            status: "cached".into(),
                            input_id: iid,
                            output_id: oid.into(),
                        });
                        return Ok(());
                    }
                }
            }
            if let Some(oid) = remote.get(&iid) {
                done.insert(id.into(), oid.clone());
                rec.targets.push(Tr {
                    id: id.into(),
                    status: "remote".into(),
                    input_id: iid,
                    output_id: oid,
                });
                return Ok(());
            }
        }
        let (status, oid) = self.execute(t)?;
        done.insert(id.into(), oid.clone());
        if cacheable && status == "ok" {
            std::fs::write(cache.join(format!("{iid}.json")), format!("{iid}\n{oid}\n"))?;
            let _ = remote.put(&iid, &oid);
        }
        rec.targets.push(Tr {
            id: id.into(),
            status,
            input_id: iid,
            output_id: oid,
        });
        Ok(())
    }
    fn execute(&self, t: &Target) -> std::io::Result<(String, String)> {
        match t.kind.as_str() {
            "shell" => {
                let cmd = t.cmd.as_deref().unwrap_or("");
                let s = std::process::Command::new("sh")
                    .arg("-c")
                    .arg(cmd)
                    .current_dir(&self.repo)
                    .status()?;
                Ok((
                    if s.success() {
                        "ok".into()
                    } else {
                        "fail".into()
                    },
                    addr::Id::of(cmd.as_bytes()).hex(),
                ))
            }
            "checks" => {
                let d = self.repo.join(t.dir.as_deref().unwrap_or("checks"));
                let mut fail = false;
                if d.is_dir() {
                    for e in std::fs::read_dir(&d)? {
                        let e = e?;
                        if e.path().is_dir() {
                            continue;
                        }
                        if e.path().extension().map(|x| x == "sh").unwrap_or(false) {
                            let s = std::process::Command::new("bash")
                                .arg(e.path())
                                .current_dir(&self.repo)
                                .status()?;
                            if !s.success() {
                                fail = true;
                            }
                        }
                    }
                }
                Ok((
                    if fail { "fail".into() } else { "ok".into() },
                    addr::Id::of_dir(&d)?.hex(),
                ))
            }
            "composite" | "receipt" | "gloss" => {
                Ok(("ok".into(), addr::Id::of(t.id.as_bytes()).hex()))
            }
            other => Err(std::io::Error::new(
                std::io::ErrorKind::InvalidInput,
                format!("kind {other}"),
            )),
        }
    }
}
