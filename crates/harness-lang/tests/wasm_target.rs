use harness_lang::*;
#[test]
fn parses_wasm_target() {
    let src = r#"harness w { target : wasm "fixtures/hello.wasm"; nonclaim : "x"; }"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.target.kind, TargetKind::Wasm);
}
#[test]
fn missing_wasm_file_fails_at_runtime() {
    let src = r#"harness w { target : wasm "fixtures/nope.wasm"; nonclaim : "x"; }"#;
    let h = Parser::new(src).parse().expect("parse");
    assert!(run(&h, ".").is_err());
}
