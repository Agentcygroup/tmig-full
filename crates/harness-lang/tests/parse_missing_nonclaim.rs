use harness_lang::*;
const SRC: &str = r#"harness bad { target : shell "true"; }"#;
#[test]
fn refuses_missing_nonclaim() {
    assert!(matches!(
        Parser::new(SRC).parse().unwrap_err(),
        ParseError::MissingNonclaim(_)
    ));
}
