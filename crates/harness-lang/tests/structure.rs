use harness_lang::*;

#[test]
fn parses_all_input_kinds() {
    let src = r#"
harness h {
    target   : shell "true";
    input    : file "a.txt";
    input    : stdin "some content";
    input    : env "KEY=VAL";
    nonclaim : "all inputs";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.inputs.len(), 3);
    assert_eq!(h.inputs[0].kind, InputKind::File);
    assert_eq!(h.inputs[1].kind, InputKind::Stdin);
    assert_eq!(h.inputs[2].kind, InputKind::Env);
}

#[test]
fn parses_all_evidence_kinds() {
    for (kw, expected) in [
        ("receipt", EvidenceKind::Receipt),
        ("log", EvidenceKind::Log),
        ("hash", EvidenceKind::Hash),
    ] {
        let src = format!(
            r#"
harness h {{
    target   : shell "true";
    evidence : {} "body";
    nonclaim : "x";
}}
"#,
            kw
        );
        let h = Parser::new(&src).parse().expect("parse");
        assert_eq!(h.evidence.unwrap().kind, expected, "kind {}", kw);
    }
}

#[test]
fn parses_all_target_kinds() {
    for (kw, expected) in [
        ("shell", TargetKind::Shell),
        ("binary", TargetKind::Binary),
        ("function", TargetKind::Function),
        ("wasm", TargetKind::Wasm),
    ] {
        let src = format!(
            r#"
harness h {{
    target   : {} "body";
    nonclaim : "x";
}}
"#,
            kw
        );
        let h = Parser::new(&src).parse().expect("parse");
        assert_eq!(h.target.kind, expected, "kind {}", kw);
    }
}

#[test]
fn field_order_is_flexible() {
    // nonclaim before target — should still parse.
    let src = r#"
harness h {
    nonclaim : "first";
    target   : shell "true";
    assert   : exit == 0;
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.target.kind, TargetKind::Shell);
    assert_eq!(h.nonclaim.as_str(), "first");
}

#[test]
fn empty_inputs_and_assertions_are_valid() {
    let src = r#"
harness h {
    target   : shell "true";
    nonclaim : "minimal";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert!(h.inputs.is_empty());
    assert!(h.assertions.is_empty());
    assert!(h.evidence.is_none());
    assert!(h.cites.is_empty());
}

#[test]
fn multiple_cites() {
    let src = r#"
harness h {
    target   : shell "true";
    nonclaim : "x";
    cite     : "A" :: "1";
    cite     : "B" :: "2";
    cite     : "C" :: "3";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.cites.len(), 3);
    assert_eq!(h.cites[2].instrument, "C");
}

#[test]
fn target_appears_last_still_works() {
    let src = r#"
harness h {
    assert   : exit == 0;
    nonclaim : "x";
    target   : shell "true";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.target.kind, TargetKind::Shell);
}

#[test]
fn trailing_whitespace_and_newlines_ok() {
    let src = "\n\n  harness h {\n  target : shell \"true\";\n  nonclaim : \"x\";\n}\n\n  ";
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.id.0, "h");
}

#[test]
fn identifiers_with_dash_underscore_digits() {
    let src = r#"
harness rule-1_a-2 {
    target   : shell "true";
    nonclaim : "x";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.id.0, "rule-1_a-2");
}
