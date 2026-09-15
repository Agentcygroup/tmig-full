use harness_lang::NonEmpty;

#[test]
fn rejects_empty() {
    assert!(NonEmpty::new("").is_none());
}

#[test]
fn rejects_whitespace_only() {
    assert!(NonEmpty::new("   ").is_none());
    assert!(NonEmpty::new("\t\n\r").is_none());
}

#[test]
fn accepts_visible_text() {
    assert_eq!(NonEmpty::new("x").unwrap().as_str(), "x");
}

#[test]
fn accepts_leading_whitespace_with_content() {
    // A nonclaim that starts with whitespace but has content is fine.
    let n = NonEmpty::new("  real text").unwrap();
    assert_eq!(n.as_str(), "  real text");
}

#[test]
fn accepts_unicode() {
    let n = NonEmpty::new("café — 日本").unwrap();
    assert_eq!(n.as_str(), "café — 日本");
}
