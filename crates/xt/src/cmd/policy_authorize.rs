//! `xt policy authorize` — evaluate one (principal, action, resource, context)
//! against the Cedar policy tree at policy/.
//!
//! Prints `allow` or `deny` on stdout and exits 0 either way. Exits 2 on
//! argument or load error.

use kernel::Constitution;
use std::path::PathBuf;

fn parse_flag(args: &[String], name: &str) -> Option<String> {
    args.iter()
        .position(|a| a == name)
        .and_then(|i| args.get(i + 1))
        .cloned()
}

/// Run `xt policy authorize`.
pub fn run(args: &[String]) -> i32 {
    let principal = match parse_flag(args, "--principal") {
        Some(v) => v,
        None => { eprintln!("missing --principal"); return 2; }
    };
    let action = match parse_flag(args, "--action") {
        Some(v) => v,
        None => { eprintln!("missing --action"); return 2; }
    };
    let resource = match parse_flag(args, "--resource") {
        Some(v) => v,
        None => { eprintln!("missing --resource"); return 2; }
    };
    let context_json = parse_flag(args, "--context")
        .unwrap_or_else(|| "{}".to_string());

    let ctx: serde_json::Value = match serde_json::from_str(&context_json) {
        Ok(v) => v,
        Err(e) => { eprintln!("bad --context json: {e}"); return 2; }
    };

    let path = PathBuf::from("policy/combined.cedar");
    if !path.exists() {
        eprintln!("policy/combined.cedar missing; run policy/check.sh to build it");
        return 2;
    }

    let constitution = match Constitution::load(&path) {
        Ok(c) => c,
        Err(e) => { eprintln!("constitution load: {e}"); return 2; }
    };

    // Build a minimal Op. The action name is the op name; effect is read.
    let op = match kernel::Op::new(&action, kernel::Effect::Read, vec![], vec![]) {
        Ok(o) => o,
        Err(e) => { eprintln!("op build: {e}"); return 2; }
    };

    // Resource id must be a valid EntityId. If not, we still want a decision.
    let target: kernel::EntityId = match resource.parse() {
        Ok(t) => t,
        Err(_) => "res:1".parse().unwrap(),
    };

    match constitution.authorize(&principal, &op, &target, ctx) {
        Ok(r) if r.verify() => {
            println!("allow");
            0
        }
        Ok(_) => {
            println!("deny");
            0
        }
        Err(kernel::Error::Denied { reason, .. }) => {
            println!("deny");
            eprintln!("reason: {reason}");
            0
        }
        Err(e) => {
            eprintln!("eval: {e}");
            2
        }
    }
}
