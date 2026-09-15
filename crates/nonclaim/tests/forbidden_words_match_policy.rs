use nonclaim::FORBIDDEN_CLAIMS;

#[test]
fn forbidden_words_appear_in_cedar_rule() {
    let cedar = std::fs::read_to_string("../../policy/rules/04-nonclaims.cedar").unwrap();
    for w in FORBIDDEN_CLAIMS {
        assert!(
            cedar.contains(w),
            "rule file does not mention forbidden word: {}",
            w
        );
    }
}

#[test]
fn empty_is_rejected() {
    assert!(nonclaim::NonClaim::new("").is_err());
    assert!(nonclaim::NonClaim::new("   ").is_err());
}

#[test]
fn mastery_is_rejected() {
    assert!(nonclaim::NonClaim::new("achieves mastery").is_err());
    assert!(nonclaim::NonClaim::new("Mastery of invariants").is_err());
}

#[test]
fn ordinary_nonclaim_is_accepted() {
    assert!(nonclaim::NonClaim::new("Interpretation only.").is_ok());
}
