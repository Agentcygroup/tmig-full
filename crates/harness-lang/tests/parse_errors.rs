use harness_lang::*;

fn err(src: &str) -> ParseError {
    Parser::new(src).parse().unwrap_err()
}

#[test]
fn unknown_target_kind() {
    let e = err(r#"harness h { target : bogus "x"; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::UnknownTargetKind(ref s) if s == "bogus"));
}

#[test]
fn unknown_input_kind() {
    let e = err(r#"harness h { target : shell "x"; input : bogus "y"; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::UnknownInputKind(ref s) if s == "bogus"));
}

#[test]
fn unknown_evidence_kind() {
    let e = err(r#"harness h { target : shell "x"; evidence : bogus "y"; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::UnknownEvidenceKind(ref s) if s == "bogus"));
}

#[test]
fn unknown_field() {
    let e = err(r#"harness h { target : shell "x"; bogus : "y"; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::UnknownField(ref s) if s == "bogus"));
}

#[test]
fn missing_target() {
    let e = err(r#"harness h { nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::MissingTarget(_)));
}

#[test]
fn empty_nonclaim() {
    let e = err(r#"harness h { target : shell "x"; nonclaim : ""; }"#);
    assert_eq!(e, ParseError::EmptyNonclaim);
}

#[test]
fn whitespace_only_nonclaim() {
    let e = err(r#"harness h { target : shell "x"; nonclaim : "   "; }"#);
    assert_eq!(e, ParseError::EmptyNonclaim);
}

#[test]
fn unexpected_eof() {
    let e = err(r#"harness h { target : shell "x""#);
    assert!(matches!(
        e,
        ParseError::UnexpectedEof | ParseError::Expected(_, _)
    ));
}

#[test]
fn unterminated_string() {
    // Genuinely unterminated: one opening quote, no closing quote before EOF.
    let e = err(r#"harness h { target : shell "unterminated"#);
    assert!(
        matches!(e, ParseError::InvalidString(_)),
        "expected InvalidString, got {:?}",
        e
    );
}

#[test]
fn missing_open_brace() {
    let e = err(r#"harness h target : shell "x"; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::Expected('{', _)));
}

#[test]
fn missing_semicolon() {
    let e = err(r#"harness h { target : shell "x" nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::Expected(';', _)));
}

#[test]
fn missing_equals_in_exit_assertion() {
    let e = err(r#"harness h { target : shell "x"; assert : exit = 0; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::Expected('=', _)));
}

#[test]
fn empty_number() {
    // exit == with no digits
    let e = err(r#"harness h { target : shell "x"; assert : exit == ; nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::InvalidNumber(_)));
}

#[test]
fn leading_keyword_is_required() {
    let e = err(r#"not_a_harness h { nonclaim : "n"; }"#);
    assert!(matches!(e, ParseError::Expected(_, _)));
}
