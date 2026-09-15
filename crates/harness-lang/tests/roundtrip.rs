use harness_lang::*;
const SOURCES: &[&str] = &[
    r#"
harness minimal {
    target   : shell "true";
    nonclaim : "minimal";
}
"#,
    r#"
harness full {
    target     : shell "cargo test -p kernel --release -- --exact constitution::tests::authorize_builds_receipt";
    input      : file "policy/rules/10-oecd-ai-principles.cedar";
    input      : env "RUST_LOG=info";
    assert     : exit == 0;
    assert     : stdout contains "1 passed";
    assert     : stdout matches ".*passed.*";
    assert     : file exists "docs/RECEIPTS.md";
    evidence   : receipt "docs/RECEIPTS.md#oecd-accountability";
    nonclaim   : "Does not assert OECD recognition or compliance.";
    cite       : "OECD/LEGAL/0449" :: "Principle 1.5";
}
"#,
];
#[test]
fn parse_print_parse_is_identity() {
    for src in SOURCES {
        let h1 = Parser::new(src).parse().expect("first parse");
        let printed = SourceEmitter.emit(&h1);
        let h2 = Parser::new(&printed)
            .parse()
            .unwrap_or_else(|e| panic!("reparse failed:\n{}\n{:?}", printed, e));
        assert_eq!(h1, h2, "round-trip mismatch\n{}", printed);
    }
}
