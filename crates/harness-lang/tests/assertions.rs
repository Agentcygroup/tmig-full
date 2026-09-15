use harness_lang::*;

#[test]
fn stdout_matches_regex_pass() {
    let src = r#"
harness h {
    target   : shell "echo 'version 1.2.3'";
    assert   : stdout matches "version [0-9]+\.[0-9]+\.[0-9]+";
    nonclaim : "regex demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(out.passed, "{:?}", out.details);
}

#[test]
fn stdout_matches_regex_fail() {
    let src = r#"
harness h {
    target   : shell "echo hello";
    assert   : stdout matches "^[0-9]+$";
    nonclaim : "regex demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(!out.passed);
}

#[test]
fn invalid_regex_errors() {
    let src = r#"
harness h {
    target   : shell "echo x";
    assert   : stdout matches "[unclosed";
    nonclaim : "regex demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let err = run(&h, ".").unwrap_err();
    assert!(matches!(err, RunError::Regex(_)));
}

#[test]
fn file_exists_pass() {
    let src = r#"
harness h {
    target   : shell "true";
    assert   : file exists "Cargo.toml";
    nonclaim : "file demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(out.passed, "{:?}", out.details);
}

#[test]
fn file_exists_fail() {
    let src = r#"
harness h {
    target   : shell "true";
    assert   : file exists "definitely-not-here.txt";
    nonclaim : "file demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(!out.passed);
}

#[test]
fn multiple_failing_assertions_all_reported() {
    let src = r#"
harness h {
    target   : shell "echo hi";
    assert   : exit == 42;
    assert   : stdout contains "bye";
    assert   : file exists "nope.txt";
    nonclaim : "multi-fail demo";
}
"#;
    let h = Parser::new(src).parse().expect("parse");
    let out = run(&h, ".").expect("run");
    assert!(!out.passed);
    assert_eq!(out.details.len(), 3);
}
