use harness_lang::*;

#[test]
fn parses_escaped_quote() {
    let src = r#"
harness h {
    target   : shell "echo \"hi\"";
    nonclaim : "contains \"quotes\"";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.target.body, r#"echo "hi""#);
    assert_eq!(h.nonclaim.as_str(), r#"contains "quotes""#);
}

#[test]
fn parses_escaped_backslash() {
    let src = r#"
harness h {
    target   : shell "echo C:\\path";
    nonclaim : "backslash demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    assert_eq!(h.target.body, r"echo C:\path");
}

#[test]
fn roundtrips_string_with_quotes() {
    let src = r#"
harness h {
    target   : shell "echo \"x\"";
    nonclaim : "has \"embedded\" quotes";
}
"#;
    let h1 = Parser::new(src).parse().expect("parse1");
    let printed = SourceEmitter.emit(&h1);
    let h2 = Parser::new(&printed)
        .parse()
        .unwrap_or_else(|e| panic!("reparse:\n{}\n{:?}", printed, e));
    assert_eq!(h1, h2);
}

#[test]
fn roundtrips_string_with_backslashes() {
    let src = r#"
harness h {
    target   : shell "echo C:\\Users\\x";
    nonclaim : "path demo";
}
"#;
    let h1 = Parser::new(src).parse().expect("parse1");
    let printed = SourceEmitter.emit(&h1);
    let h2 = Parser::new(&printed)
        .parse()
        .unwrap_or_else(|e| panic!("reparse:\n{}\n{:?}", printed, e));
    assert_eq!(h1, h2);
}

#[test]
fn roundtrips_unicode() {
    let src = r#"
harness h {
    target   : shell "echo café";
    nonclaim : "日本 — ok";
}
"#;
    let h1 = Parser::new(src).parse().expect("parse1");
    let printed = SourceEmitter.emit(&h1);
    let h2 = Parser::new(&printed)
        .parse()
        .unwrap_or_else(|e| panic!("reparse:\n{}\n{:?}", printed, e));
    assert_eq!(h1, h2);
}
