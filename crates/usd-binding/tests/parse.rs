use usd_binding::parse;

#[test]
fn extracts_actions() {
    let src = std::fs::read_to_string("../../spec/actions/actions.usda").expect("actions.usda");
    let prims = parse(&src);
    let actions: Vec<_> = prims.iter().filter(|p| p.ty == "Action").collect();
    assert_eq!(actions.len(), 6, "expected 6 actions");
    for a in &actions {
        assert!(
            a.strings.contains_key("cedar_action"),
            "{} missing cedar_action",
            a.name
        );
        assert!(
            a.strings.contains_key("nonclaim"),
            "{} missing nonclaim",
            a.name
        );
    }
}

#[test]
fn extracts_behaviors() {
    let src =
        std::fs::read_to_string("../../spec/behaviors/behaviors.usda").expect("behaviors.usda");
    let prims = parse(&src);
    let behaviors: Vec<_> = prims.iter().filter(|p| p.ty == "Behavior").collect();
    assert!(
        behaviors.len() >= 8,
        "expected >=8 behaviors, got {}",
        behaviors.len()
    );
    for b in &behaviors {
        assert!(b.strings.contains_key("crate"), "{} missing crate", b.name);
        assert!(
            b.strings.contains_key("nonclaim"),
            "{} missing nonclaim",
            b.name
        );
    }
}
