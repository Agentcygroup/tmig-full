use harness_lang::{Assertion, Harness, InputKind, TargetKind};
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Plan,
    Design,
    Build,
    Test,
    Release,
    Deploy,
    Operate,
    Maintain,
    Retire,
}

pub const ALL_PHASES: &[Phase] = &[
    Phase::Plan,
    Phase::Design,
    Phase::Build,
    Phase::Test,
    Phase::Release,
    Phase::Deploy,
    Phase::Operate,
    Phase::Maintain,
    Phase::Retire,
];

impl Phase {
    pub fn parse(s: &str) -> Option<Phase> {
        Some(match s {
            "plan" => Phase::Plan,
            "design" => Phase::Design,
            "build" => Phase::Build,
            "test" => Phase::Test,
            "release" => Phase::Release,
            "deploy" => Phase::Deploy,
            "operate" => Phase::Operate,
            "maintain" => Phase::Maintain,
            "retire" => Phase::Retire,
            _ => return None,
        })
    }
    pub fn name(&self) -> &'static str {
        match self {
            Phase::Plan => "plan",
            Phase::Design => "design",
            Phase::Build => "build",
            Phase::Test => "test",
            Phase::Release => "release",
            Phase::Deploy => "deploy",
            Phase::Operate => "operate",
            Phase::Maintain => "maintain",
            Phase::Retire => "retire",
        }
    }
}

impl fmt::Display for Phase {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

#[derive(Debug)]
pub enum EmitError {
    UnknownPhase(String),
}

impl fmt::Display for EmitError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EmitError::UnknownPhase(s) => write!(f, "unknown phase: {}", s),
        }
    }
}
impl std::error::Error for EmitError {}

pub fn emit_phase(h: &Harness, phase: Phase) -> String {
    match phase {
        Phase::Plan => plan(h),
        Phase::Design => design(h),
        Phase::Build => build(h),
        Phase::Test => test(h),
        Phase::Release => release(h),
        Phase::Deploy => deploy(h),
        Phase::Operate => operate(h),
        Phase::Maintain => maintain(h),
        Phase::Retire => retire(h),
    }
}

fn escape(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

fn plan(h: &Harness) -> String {
    let mut s = format!("# Plan — {}\n\n## Acceptance criteria\n\n", h.id.0);
    if h.assertions.is_empty() {
        s.push_str("_No assertions declared._\n");
    } else {
        for (i, a) in h.assertions.iter().enumerate() {
            s.push_str(&format!(
                "{}. {}\n",
                i + 1,
                match a {
                    Assertion::Exit(n) => format!("Exit code is `{}`", n),
                    Assertion::StdoutContains(x) => format!("stdout contains `{}`", x),
                    Assertion::StdoutMatches(x) => format!("stdout matches `{}`", x),
                    Assertion::FileExists(x) => format!("file `{}` exists", x),
                }
            ));
        }
    }
    s.push_str(&format!("\n## Non-claims\n\n> {}\n", h.nonclaim.as_str()));
    s
}

fn design(h: &Harness) -> String {
    let mut s = format!(
        "// Design stub: {}\n// nonclaim: {}\n\n",
        h.id.0,
        h.nonclaim.as_str()
    );
    for c in &h.cites {
        s.push_str(&format!("// cite: {} :: {}\n", c.instrument, c.clause));
    }
    s.push_str(&format!(
        "permit(\n    principal,\n    action == Action::\"run_{}\",\n    resource\n)\nwhen {{ context.nonclaim != \"\" }};\n",
        h.id.0.replace('-', "_")));
    s
}

fn build(h: &Harness) -> String {
    let mut s = format!("# Build — {}\n", h.id.0);
    for i in &h.inputs {
        s.push_str(&format!(
            "# input({}): {}\n",
            match i.kind {
                InputKind::File => "file",
                InputKind::Stdin => "stdin",
                InputKind::Env => "env",
            },
            i.body
        ));
    }
    s.push_str(&h.target.body);
    s.push('\n');
    s
}

fn test(h: &Harness) -> String {
    format!(
        "#[test]\nfn {}() {{\n    let src = include_str!(\"../harnesses/{}.harness\");\n    let h = harness_lang::Parser::new(src).parse().expect(\"parse\");\n    let out = harness_lang::run(&h, \".\").expect(\"run\");\n    assert!(out.passed, \"{{:?}}\", out.details);\n}}\n",
        h.id.0.replace('-', "_"), h.id.0)
}

fn release(h: &Harness) -> String {
    let mut s = format!("## {}\n\n", h.id.0);
    s.push_str(&format!(
        "- target: `{}` ({})\n",
        escape(&h.target.body),
        match h.target.kind {
            TargetKind::Shell => "shell",
            TargetKind::Binary => "binary",
            TargetKind::Function => "function",
            TargetKind::Wasm => "wasm",
        }
    ));
    for a in &h.assertions {
        s.push_str(&format!(
            "- assertion: {}\n",
            match a {
                Assertion::Exit(n) => format!("exit == {}", n),
                Assertion::StdoutContains(x) => format!("stdout contains {:?}", x),
                Assertion::StdoutMatches(x) => format!("stdout matches {:?}", x),
                Assertion::FileExists(x) => format!("file exists {:?}", x),
            }
        ));
    }
    if let Some(e) = &h.evidence {
        s.push_str(&format!("- evidence ({:?}): `{}`\n", e.kind, e.body));
    }
    s.push_str(&format!("\n> nonclaim: {}\n", h.nonclaim.as_str()));
    s
}

#[derive(serde::Serialize)]
struct CiJob {
    #[serde(rename = "runs-on")]
    runs_on: String,
    steps: Vec<CiStep>,
}

#[derive(serde::Serialize)]
struct CiStep {
    name: String,
    run: String,
}

fn deploy(h: &Harness) -> String {
    let job = CiJob {
        runs_on: "ubuntu-latest".into(),
        steps: vec![
            CiStep {
                name: "checkout".into(),
                run: "uses: actions/checkout@v4".into(),
            },
            CiStep {
                name: h.id.0.clone(),
                run: h.target.body.clone(),
            },
        ],
    };
    let mut map = std::collections::BTreeMap::new();
    map.insert(h.id.0.clone(), job);
    serde_yaml::to_string(&map).unwrap_or_default()
}

fn operate(h: &Harness) -> String {
    format!(
        "# healthcheck for {}\n*/5 * * * * cd $REPO && {} >/dev/null 2>&1 || echo 'FAIL: {}'\n",
        h.id.0, h.target.body, h.id.0
    )
}

fn maintain(h: &Harness) -> String {
    format!(
        "# maintain: {}\n# nonclaim: {}\n",
        h.id.0,
        h.nonclaim.as_str()
    )
}

fn retire(h: &Harness) -> String {
    format!(
        "# retire manifest for {}\nid: {}\nreason: <fill in>\nsuperseded_by: <fill in>\narchive:\n  - target: {}\n  - nonclaim: {}\n",
        h.id.0, h.id.0, escape(&h.target.body), escape(h.nonclaim.as_str()))
}
