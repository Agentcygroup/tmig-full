use harness_lang::*;
const SRC: &str = r#"
harness demo {
    target   : shell "true";
    assert   : exit == 0;
    nonclaim : "demo";
}
"#;
#[test]
fn shell_emitter_carries_nonclaim() {
    let h = Parser::new(SRC).parse().expect("parse");
    let sh = ShellEmitter.emit(&h);
    assert!(sh.contains("set -euo pipefail"));
    assert!(sh.contains("nonclaim: demo"));
}
#[test]
fn json_emitter_roundtrips() {
    let h = Parser::new(SRC).parse().expect("parse");
    let back: Harness = serde_json::from_str(&JsonEmitter.emit(&h)).expect("roundtrip");
    assert_eq!(h, back);
}
