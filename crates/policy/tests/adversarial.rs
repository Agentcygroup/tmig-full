//! Adversarial tests. Trees that pass every Rust check but violate a
//! Cedar policy. Prove the policy layer does work the Rust layer cannot.

use cedar_policy::{Authorizer, Entities, PolicySet};

#[test]
fn strength_floor_enforced_by_policy_not_rust() {
    let src = r#"
        forbid (principal, action, resource)
        when { context.strength < 10 };
    "#;
    let policies = PolicySet::from_str(src).expect("parse");
    let req = policy::request_for("project", 5, "some-target", "shell", Some("echo hi"))
        .expect("request");
    let d = Authorizer::new().is_authorized(&req, &policies, &Entities::empty());
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
    let req = policy::request_for("produced", 15, "t1", "shell", Some("nc -l 9999"))
        .expect("request");
    let d = Authorizer::new().is_authorized(&req, &policies, &Entities::empty());
    assert!(matches!(d.decision(), cedar_policy::Decision::Deny));
}
