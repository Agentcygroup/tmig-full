use harness_lang::Parser;
use sdcl::{emit_phase, Phase, ALL_PHASES};

const SRC: &str = r#"
harness demo {
    target   : shell "cargo test -p kernel --release";
    assert   : exit == 0;
    nonclaim : "demo nonclaim";
    cite     : "OECD/LEGAL/0449" :: "Principle 1.5";
}
"#;

fn h() -> harness_lang::Harness {
    Parser::new(SRC).parse().expect("parse")
}

#[test]
fn cross_cut_is_structural() {
    assert_eq!(ALL_PHASES.len(), 9);
    let h = h();
    for p in ALL_PHASES {
        assert!(!emit_phase(&h, *p).trim().is_empty());
    }
}

#[test]
fn phases_are_orthogonal() {
    let h = h();
    for a in ALL_PHASES {
        for b in ALL_PHASES {
            if a == b {
                continue;
            }
            let (sa, sb) = (emit_phase(&h, *a), emit_phase(&h, *b));
            assert!(
                !sa.starts_with(&sb) || sa == sb,
                "phase {} output starts with phase {} output",
                a,
                b
            );
        }
    }
}

#[test]
fn deploy_emits_valid_yaml() {
    let h = h();
    let yaml = emit_phase(&h, Phase::Deploy);
    let parsed: serde_yaml::Value =
        serde_yaml::from_str(&yaml).expect("deploy output must be valid YAML");
    let job = &parsed[&h.id.0];
    assert_eq!(job["runs-on"].as_str(), Some("ubuntu-latest"));
    let steps = job["steps"].as_sequence().expect("steps array");
    assert!(steps.len() >= 2);
}

#[test]
fn sdcl_requires_a_parseable_harness() {
    let bad = r#"harness h { target : shell "true"; }"#;
    assert!(Parser::new(bad).parse().is_err());
}

#[test]
fn sdcl_input_type_is_harness() {
    let h = h();
    let _: String = emit_phase(&h, Phase::Build);
}
