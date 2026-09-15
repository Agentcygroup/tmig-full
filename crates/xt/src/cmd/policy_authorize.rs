//! `xt policy authorize` — evaluate one (principal, action, resource, context)
//! against the Cedar policy tree at policy/.
//!
//! Prints `allow` or `deny` on stdout and exits 0 either way. Exits 2 on
//! argument or load error.

use kernel::{Constitution, Effect, EntityId, Op};
use std::path::{Path, PathBuf};

fn parse_flag(args: &[String], name: &str) -> Option<String> {
    args.iter()
        .position(|a| a == name)
        .and_then(|i| args.get(i + 1))
        .cloned()
}

fn collect_cedar(dir: &Path) -> Result<String, std::io::Error> {
    let mut out = String::new();
    let mut stack = vec![dir.to_path_buf()];
    while let Some(d) = stack.pop() {
        for entry in std::fs::read_dir(&d)? {
            let e = entry?;
            let p = e.path();
            if p.is_dir() {
                stack.push(p);
            } else if p.extension().map(|x| x == "cedar").unwrap_or(false) {
                out.push_str(&std::fs::read_to_string(&p)?);
                out.push('\n');
            }
        }
    }
    Ok(out)
}

/// Run `xt policy authorize`.
pub fn run(args: &[String]) -> i32 {
    let principal = match parse_flag(args, "--principal") {
        Some(v) => v,
        None => {
            eprintln!("missing --principal");
            return 2;
        }
    };
    let action = match parse_flag(args, "--action") {
        Some(v) => v,
        None => {
            eprintln!("missing --action");
            return 2;
        }
    };
    let resource = match parse_flag(args, "--resource") {
        Some(v) => v,
        None => {
            eprintln!("missing --resource");
            return 2;
        }
    };
    let context_json = parse_flag(args, "--context").unwrap_or_else(|| "{}".to_string());

    let ctx: serde_json::Value = match serde_json::from_str(&context_json) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("bad --context json: {e}");
            return 2;
        }
    };

    let policy_dir = PathBuf::from("policy");
    if !policy_dir.exists() {
        eprintln!("policy/ not found");
        return 2;
    }

    // Concatenate every .cedar in the tree into a temp file, then load
    // it as a single Constitution.
    let combined = match collect_cedar(&policy_dir) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("reading policy tree: {e}");
            return 2;
        }
    };
    let tmp = std::env::temp_dir().join(format!("xt-policy-{}.cedar", std::process::id()));
    if let Err(e) = std::fs::write(&tmp, &combined) {
        eprintln!("writing temp policy: {e}");
        return 2;
    }

    let constitution = match Constitution::load(&tmp) {
        Ok(c) => c,
        Err(e) => {
            let _ = std::fs::remove_file(&tmp);
            eprintln!("constitution load: {e}");
            return 2;
        }
    };

    let op = match Op::new(&action, Effect::Read, vec![], vec![]) {
        Ok(o) => o,
        Err(e) => {
            let _ = std::fs::remove_file(&tmp);
            eprintln!("op build: {e}");
            return 2;
        }
    };

    let target: EntityId = match resource.parse() {
        Ok(t) => t,
        Err(_) => "res:1".parse().unwrap(),
    };

    let result = constitution.authorize(&principal, &op, &target, ctx);
    let _ = std::fs::remove_file(&tmp);

    match result {
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
