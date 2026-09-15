use harness_lang::*;
const SRC: &str = r#"
harness hello {
    target   : shell "echo hello";
    assert   : exit == 0;
    assert   : stdout contains "hello";
    nonclaim : "just a demo";
}
"#;
#[test]
fn runs_and_passes() {
    let h = Parser::new(SRC).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(out.passed, "{:?}", out.details);
}
