use std::process::exit;
fn main() {
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
        "policy-check" => {
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
        "help" => eprintln!("usage: xt <target|plan|show|non-claims|policy|remote>"),
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
