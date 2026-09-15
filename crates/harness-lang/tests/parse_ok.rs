use harness_lang::*;
const SRC: &str = r#"
harness oecd-accountability {
    target     : shell "cargo test -p kernel --release -- --exact constitution::tests::authorize_builds_receipt";
    input      : file "policy/rules/10-oecd-ai-principles.cedar";
    assert     : exit == 0;
    assert     : stdout contains "1 passed";
    evidence   : receipt "docs/RECEIPTS.md#oecd-accountability";
    nonclaim   : "Does not assert OECD recognition or compliance.";
    cite       : "OECD/LEGAL/0449" :: "Principle 1.5";
}
"#;
#[test]
fn parses_full_harness() {
    let h = Parser::new(SRC).parse().expect("parse");
    assert_eq!(h.id.0, "oecd-accountability");
    assert_eq!(h.target.kind, TargetKind::Shell);
    assert_eq!(h.inputs.len(), 1);
    assert_eq!(h.assertions.len(), 2);
    assert_eq!(h.cites.len(), 1);
}
