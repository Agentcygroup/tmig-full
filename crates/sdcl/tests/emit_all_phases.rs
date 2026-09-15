use harness_lang::Parser;
use sdcl::{emit_phase, Phase, ALL_PHASES};

const SRC: &str = r#"
harness demo {
    target     : shell "cargo test -p kernel --release";
    input      : file "policy/rules/10-oecd-ai-principles.cedar";
    assert     : exit == 0;
    assert     : stdout contains "passed";
    evidence   : receipt "docs/RECEIPTS.md#demo";
    nonclaim   : "demo nonclaim";
    cite       : "OECD/LEGAL/0449" :: "Principle 1.5";
}
"#;

fn h() -> harness_lang::Harness {
    Parser::new(SRC).parse().expect("parse")
}

#[test]
fn every_phase_emits_something() {
    let h = h();
    for p in ALL_PHASES {
        assert!(!emit_phase(&h, *p).trim().is_empty(), "phase {} empty", p);
    }
}

#[test]
fn all_phase_names_roundtrip() {
    for p in ALL_PHASES {
        assert_eq!(Phase::parse(p.name()), Some(*p));
    }
}

#[test]
fn unknown_phase_returns_none() {
    assert!(Phase::parse("nonsense").is_none());
}

#[test]
fn build_phase_contains_target_body() {
    let h = h();
    assert!(emit_phase(&h, Phase::Build).contains("cargo test -p kernel --release"));
}

#[test]
fn test_phase_is_a_rust_test() {
    let h = h();
    let out = emit_phase(&h, Phase::Test);
    assert!(out.starts_with("#[test]"));
    assert!(out.contains("harness_lang::Parser::new"));
}
