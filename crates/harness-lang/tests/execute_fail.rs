use harness_lang::*;
const SRC: &str = r#"
harness failing {
    target   : shell "echo nope";
    assert   : stdout contains "yes";
    nonclaim : "demo of failure";
}
"#;
#[test]
fn fails_when_assertion_fails() {
    let h = Parser::new(SRC).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(!out.passed);
    assert_eq!(out.details.len(), 1);
}
