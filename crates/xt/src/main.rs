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
        "help" => eprintln!("usage: xt <target|plan|show|non-claims>"),
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
