use super::Emitter;
use crate::artifact::*;
pub struct SourceEmitter;
impl Emitter for SourceEmitter {
    fn emit(&self, h: &Harness) -> String {
        let mut s = String::new();
        s.push_str(&format!("harness {} {{\n", h.id.0));
        s.push_str(&format!(
            "    target : {} \"{}\";\n",
            target_kw(&h.target.kind),
            escape(&h.target.body)
        ));
        for i in &h.inputs {
            s.push_str(&format!(
                "    input : {} \"{}\";\n",
                input_kw(&i.kind),
                escape(&i.body)
            ));
        }
        for a in &h.assertions {
            match a {
                Assertion::Exit(n) => s.push_str(&format!("    assert : exit == {};\n", n)),
                Assertion::StdoutContains(x) => s.push_str(&format!(
                    "    assert : stdout contains \"{}\";\n",
                    escape(x)
                )),
                Assertion::StdoutMatches(x) => {
                    s.push_str(&format!("    assert : stdout matches \"{}\";\n", escape(x)))
                }
                Assertion::FileExists(x) => {
                    s.push_str(&format!("    assert : file exists \"{}\";\n", escape(x)))
                }
            }
        }
        if let Some(e) = &h.evidence {
            s.push_str(&format!(
                "    evidence : {} \"{}\";\n",
                evidence_kw(&e.kind),
                escape(&e.body)
            ));
        }
        s.push_str(&format!(
            "    nonclaim : \"{}\";\n",
            escape(h.nonclaim.as_str())
        ));
        for c in &h.cites {
            s.push_str(&format!(
                "    cite : \"{}\" :: \"{}\";\n",
                escape(&c.instrument),
                escape(&c.clause)
            ));
        }
        s.push_str("}\n");
        s
    }
}
fn target_kw(k: &TargetKind) -> &'static str {
    match k {
        TargetKind::Shell => "shell",
        TargetKind::Binary => "binary",
        TargetKind::Function => "function",
        TargetKind::Wasm => "wasm",
    }
}
fn input_kw(k: &InputKind) -> &'static str {
    match k {
        InputKind::File => "file",
        InputKind::Stdin => "stdin",
        InputKind::Env => "env",
    }
}
fn evidence_kw(k: &EvidenceKind) -> &'static str {
    match k {
        EvidenceKind::Receipt => "receipt",
        EvidenceKind::Log => "log",
        EvidenceKind::Hash => "hash",
    }
}
fn escape(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}
