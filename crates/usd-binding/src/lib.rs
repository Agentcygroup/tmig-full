//! Minimal reader for the .usda subset used in spec/.
//! Extracts `def <Type> "<name>"` prims and `string <key> = "<value>"`
//! attributes. Not a general USD parser.

use std::collections::BTreeMap;

#[derive(Debug, Default)]
pub struct Prim {
    pub ty: String,
    pub name: String,
    pub strings: BTreeMap<String, String>,
    pub rels: BTreeMap<String, String>,
}

pub fn parse(src: &str) -> Vec<Prim> {
    let mut prims: Vec<Prim> = Vec::new();
    let mut current: Option<Prim> = None;

    for raw in src.lines() {
        let line = raw.trim();

        if let Some(rest) = line.strip_prefix("def ") {
            if let Some(p) = current.take() {
                prims.push(p);
            }
            let mut parts = rest.splitn(2, char::is_whitespace);
            let ty = parts.next().unwrap_or("").to_string();
            let after = parts.next().unwrap_or("");
            let name = after
                .trim_start_matches('"')
                .split('"')
                .next()
                .unwrap_or("")
                .to_string();
            current = Some(Prim {
                ty,
                name,
                strings: BTreeMap::new(),
                rels: BTreeMap::new(),
            });
            continue;
        }

        if let Some(p) = current.as_mut() {
            if let Some(rest) = line.strip_prefix("rel ") {
                if let Some((k, v)) = rest.split_once('=') {
                    let key = k.trim().to_string();
                    let val = v.trim().trim_end_matches(';').trim().to_string();
                    p.rels.insert(key, val);
                }
                continue;
            }
            if let Some(rest) = line.strip_prefix("string ") {
                if let Some((k, v)) = rest.split_once('=') {
                    let key = k.trim().to_string();
                    let val = v
                        .trim()
                        .trim_start_matches('"')
                        .split('"')
                        .next()
                        .unwrap_or("")
                        .to_string();
                    p.strings.insert(key, val);
                }
            }
        }
    }

    if let Some(p) = current.take() {
        prims.push(p);
    }
    prims
}
