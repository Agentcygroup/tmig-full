//! producers — expand the tree into targets without a hardcoded list.
use layer::Target;
use serde::Deserialize;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Deserialize)]
pub struct Producer {
    pub id: String,
    pub class: String,
    #[serde(default, rename = "match")]
    pub match_file: Option<String>,
    #[serde(default)]
    pub glob: Option<String>,
    #[serde(default)]
    pub root: Option<String>,
    #[serde(default)]
    pub strength: Option<u32>,
    #[serde(default)]
    pub kind: Option<String>,
    #[serde(default)]
    pub cmd_template: Option<String>,
    #[serde(default)]
    pub id_template: Option<String>,
    #[serde(default)]
    pub optional: Option<bool>,
    #[serde(default)]
    pub target: Vec<ProducerTarget>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProducerTarget {
    pub id: String,
    pub kind: String,
    #[serde(default)]
    pub cmd: Option<String>,
    #[serde(default)]
    pub dir: Option<String>,
    #[serde(default)]
    pub needs: Vec<String>,
    #[serde(default)]
    pub optional: bool,
}

pub fn load_all(dir: &Path) -> Vec<Producer> {
    let mut out = Vec::new();
    if !dir.is_dir() {
        eprintln!("[producers] not a dir: {}", dir.display());
        return out;
    }
    let mut files: Vec<_> = std::fs::read_dir(dir)
        .ok()
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map(|x| x == "toml").unwrap_or(false))
        .collect();
    files.sort_by_key(|e| e.path());
    for f in files {
        match std::fs::read_to_string(f.path()) {
            Ok(txt) => match toml::from_str::<Producer>(&txt) {
                Ok(p) => out.push(p),
                Err(e) => eprintln!("[producers] parse error {}: {}", f.path().display(), e),
            },
            Err(e) => eprintln!("[producers] read error {}: {}", f.path().display(), e),
        }
    }
    out
}

pub fn expand(repo: &Path, producers: &[Producer]) -> Vec<Target> {
    let mut targets = Vec::new();
    for p in producers {
        let produced = match p.class.as_str() {
            "manifest" => expand_manifest(repo, p),
            "treewalk" => expand_treewalk(repo, p),
            "standard-set" => expand_standard_set(p),
            other => {
                eprintln!("[producers] unknown class {} for {}", other, p.id);
                Vec::new()
            }
        };
        targets.extend(produced);
    }
    targets
}

fn expand_manifest(repo: &Path, p: &Producer) -> Vec<Target> {
    let Some(name) = p.match_file.as_deref() else {
        return Vec::new();
    };
    if !repo.join(name).exists() {
        return Vec::new();
    }
    p.target
        .iter()
        .map(|t| Target {
            id: format!("{}:{}", p.id, t.id),
            kind: t.kind.clone(),
            cmd: t.cmd.clone(),
            dir: t.dir.clone(),
            needs: t.needs.iter().map(|n| format!("{}:{}", p.id, n)).collect(),
            optional: t.optional,
        })
        .collect()
}

fn expand_treewalk(repo: &Path, p: &Producer) -> Vec<Target> {
    let Some(glob_pat) = p.glob.as_deref() else {
        return Vec::new();
    };
    let root: PathBuf = match p.root.as_deref() {
        Some("$INTENT/standards") => std::env::var("HOME")
            .map(|h| PathBuf::from(h).join("intent").join("standards"))
            .unwrap_or_else(|_| PathBuf::from(".")),
        _ => repo.to_path_buf(),
    };
    let pattern = format!("{}/{}", root.display(), glob_pat);
    let mut out = Vec::new();
    let Ok(entries) = glob::glob(&pattern) else {
        return out;
    };
    for e in entries.filter_map(|e| e.ok()) {
        let rel = e
            .strip_prefix(repo)
            .unwrap_or(&e)
            .to_string_lossy()
            .to_string();
        let stem = e
            .file_stem()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_default();
        let id = p
            .id_template
            .as_deref()
            .unwrap_or("target:{path}")
            .replace("{path}", &rel)
            .replace("{stem}", &stem);
        let cmd = p
            .cmd_template
            .as_deref()
            .unwrap_or("true")
            .replace("{path}", &rel)
            .replace("{stem}", &stem);
        out.push(Target {
            id,
            kind: p.kind.clone().unwrap_or_else(|| "shell".into()),
            cmd: Some(cmd),
            dir: None,
            needs: Vec::new(),
            optional: p.optional.unwrap_or(true),
        });
    }
    out
}

fn expand_standard_set(p: &Producer) -> Vec<Target> {
    vec![Target {
        id: format!("{}:all", p.id),
        kind: p.kind.clone().unwrap_or_else(|| "shell".into()),
        cmd: p
            .cmd_template
            .clone()
            .or_else(|| Some("REPO=$PWD JOBS=8 xt-parallel".into())),
        dir: None,
        needs: Vec::new(),
        optional: p.optional.unwrap_or(true),
    }]
}
