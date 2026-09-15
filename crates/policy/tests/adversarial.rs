use std::str::FromStr;
// Adversarial tests. A policy that denies a request the Rust code
// would accept. Proves the policy layer does real work.

use cedar_policy::{Authorizer, Context, Entities, PolicySet, Request};

fn req(layer: &str, strength: u32, cmd: &str) -> Request {
    let p = r#"Principal::"xt""#.parse().unwrap();
    let a = r#"Action::"shell""#.parse().unwrap();
    let r = r#"Resource::"t1""#.parse().unwrap();
    let ctx = Context::from_json_str(
        &serde_json::json!({ "layer": layer, "strength": strength, "cmd": cmd }).to_string(),
        None,
    )
    .unwrap();
    Request::new(p, a, r, ctx, None).unwrap()
}

#[test]
fn strength_floor_enforced_by_policy_not_rust() {
    let src = r#"
        forbid (principal, action, resource)
        when { context.strength < 10 };
    "#;
    let policies = PolicySet::from_str(src).expect("parse");
    let r = req("project", 5, "echo hi");
    let d = Authorizer::new().is_authorized(&r, &policies, &Entities::empty());
    assert!(matches!(d.decision(), cedar_policy::Decision::Deny));
}

#[test]
fn boundary_denies_forbidden_verbs() {
    let src = r#"
        forbid (principal, action, resource)
        when {
            context.cmd like "*nc -l*"      ||
            context.cmd like "*socat*"      ||
            context.cmd like "*docker run*"
        };
    "#;
    let policies = PolicySet::from_str(src).expect("parse");
    let r = req("produced", 15, "nc -l 9999");
    let d = Authorizer::new().is_authorized(&r, &policies, &Entities::empty());
    assert!(matches!(d.decision(), cedar_policy::Decision::Deny));
}
