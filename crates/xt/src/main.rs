//! xt — CLI dispatcher.
//!
//! Subcommands:
//!   xt plan | show
//!   xt non-claims
//!   xt policy-check
//!   xt policy authorize --principal P --action A --resource R --context JSON
//!   xt kernel check | load
//!   xt remote

mod cmd;

use std::process::exit;

fn dispatch() {
    let repo = std::env::current_dir().expect("cwd");
    let args: Vec<String> = std::env::args().skip(1).collect();
    let task = args.first().map(String::as_str).unwrap_or("help");

    let i = match intent::load(&repo) {
        Ok(i) => i,
        Err(e) => {
            eprintln!("{e}");
            exit(2);
        }
    };

    match task {
        "kernel" => {
            exit(cmd::kernel::run(&args[1..]));
        }
        "policy" => {
            if args.get(1).map(String::as_str) == Some("authorize") {
                exit(cmd::policy_authorize::run(&args[2..]));
            }
            run_policy_check(&repo, &i);
        }
        "plan" | "show" => {
            for (id, (s, t)) in &i.resolve().targets {
                println!(
                    "{s:>4}  {id:<14} {:<10} {}",
                    t.kind,
                    t.cmd.as_deref().unwrap_or("")
                );
            }
        }
        "non-claims" => {
            for n in [
                "no-mastery",
                "no-accreditation",
                "no-coherence-proof",
                "no-completeness",
            ] {
                println!("{n}");
            }
        }
        "remote" => {
            let r = std::env::var("XT_REMOTE")
                .map(std::path::PathBuf::from)
                .unwrap_or_else(|_| repo.join("target").join("xt-remote"));
            match remote::Remote::open(&r) {
                Ok(_) => println!("remote cache: {}", r.display()),
                Err(e) => {
                    eprintln!("{e}");
                    exit(1);
                }
            }
        }
        "policy-check" => run_policy_check(&repo, &i),
        "help" => {
            eprintln!("usage: xt <plan|show|policy-check|policy authorize|kernel|non-claims|remote>")
        }
        target => match i.run(target) {
            Ok(r) => {
                println!("run {}", r.run_id);
                for t in &r.targets {
                    println!("  {:<7} {}", t.status, t.id);
                }
            }
            Err(e) => {
                eprintln!("{target}: {e}");
                exit(1);
            }
        },
    }
}

fn run_policy_check(repo: &std::path::Path, i: &intent::Intent) {
    let dir = repo.join("policies");
    let bundle = match policy::load(&dir) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("policy: {e}");
            exit(2);
        }
    };
    let mut reqs = Vec::new();
    for (name, layer) in &i.layers {
        for target in &layer.targets {
            match policy::request_for(
                name,
                layer.strength,
                &target.id,
                &target.kind,
                target.cmd.as_deref(),
            ) {
                Ok(r) => reqs.push(r),
                Err(e) => {
                    eprintln!("policy: request: {e}");
                    exit(2);
                }
            }
        }
    }
    match policy::check(&bundle, &reqs) {
        Ok(()) => println!("policy: ok ({} requests)", reqs.len()),
        Err(vs) => {
            for v in &vs {
                eprintln!("violation: {} — {}", v.policy_id, v.reason);
            }
            exit(1);
        }
    }
}

fn main() {
    dispatch();
}
