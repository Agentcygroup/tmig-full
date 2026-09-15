use usd_binding::parse;

#[test]
fn every_emergence_has_two_rels_and_a_check() {
    let src =
        std::fs::read_to_string("../../spec/emergence/emergence.usda").expect("emergence.usda");
    let prims = parse(&src);
    let emergences: Vec<_> = prims.iter().filter(|p| p.ty == "Emergence").collect();
    assert!(
        emergences.len() >= 8,
        "expected >=8 emergences, got {}",
        emergences.len()
    );
    for e in &emergences {
        assert!(
            e.rels.contains_key("from_action"),
            "{} missing from_action",
            e.name
        );
        assert!(
            e.rels.contains_key("from_behavior"),
            "{} missing from_behavior",
            e.name
        );
        assert!(e.strings.contains_key("check"), "{} missing check", e.name);
        assert!(
            e.strings.contains_key("nonclaim"),
            "{} missing nonclaim",
            e.name
        );
    }
}
