use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Harness {
    pub id: Ident,
    pub target: Target,
    pub inputs: Vec<Input>,
    pub assertions: Vec<Assertion>,
    pub evidence: Option<Evidence>,
    pub nonclaim: NonEmpty,
    pub cites: Vec<Cite>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Target {
    pub kind: TargetKind,
    pub body: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TargetKind {
    Shell,
    Binary,
    Function,
    Wasm,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Input {
    pub kind: InputKind,
    pub body: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum InputKind {
    File,
    Stdin,
    Env,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Assertion {
    Exit(i32),
    StdoutContains(String),
    StdoutMatches(String),
    FileExists(String),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Evidence {
    pub kind: EvidenceKind,
    pub body: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum EvidenceKind {
    Receipt,
    Log,
    Hash,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Cite {
    pub instrument: String,
    pub clause: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Ident(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct NonEmpty(pub String);

impl NonEmpty {
    pub fn new(s: impl Into<String>) -> Option<Self> {
        let s = s.into();
        if s.trim().is_empty() {
            None
        } else {
            Some(Self(s))
        }
    }
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
