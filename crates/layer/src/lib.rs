use serde::Deserialize;
use std::collections::BTreeMap;
#[derive(Debug, Clone, Deserialize)]
pub struct LayerFile {
    pub layers: BTreeMap<String, Layer>,
}
#[derive(Debug, Clone, Deserialize)]
pub struct Layer {
    pub strength: u32,
    #[serde(default, rename = "target")]
    pub targets: Vec<Target>,
}
#[derive(Debug, Clone, Deserialize)]
pub struct Target {
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
#[derive(Debug, Default)]
pub struct Resolved {
    pub targets: BTreeMap<String, (u32, Target)>,
}
pub fn resolve(layers: &[(String, Layer)]) -> Resolved {
    let mut r = Resolved::default();
    let mut s: Vec<_> = layers.iter().collect();
    s.sort_by(|a, b| b.1.strength.cmp(&a.1.strength).then_with(|| a.0.cmp(&b.0)));
    for (_, l) in s {
        for t in &l.targets {
            r.targets
                .entry(t.id.clone())
                .and_modify(|e| {
                    if l.strength > e.0 {
                        *e = (l.strength, t.clone());
                    }
                })
                .or_insert((l.strength, t.clone()));
        }
    }
    r
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn higher_wins() {
        let a = Layer {
            strength: 10,
            targets: vec![Target {
                id: "b".into(),
                kind: "shell".into(),
                cmd: Some("a".into()),
                dir: None,
                needs: vec![],
                optional: false,
            }],
        };
        let b = Layer {
            strength: 90,
            targets: vec![Target {
                id: "b".into(),
                kind: "shell".into(),
                cmd: Some("b".into()),
                dir: None,
                needs: vec![],
                optional: false,
            }],
        };
        assert_eq!(
            resolve(&[("a".into(), a), ("b".into(), b)]).targets["b"]
                .1
                .cmd
                .as_deref(),
            Some("b")
        );
    }
}
