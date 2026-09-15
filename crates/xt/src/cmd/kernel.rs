//! `xt kernel` subcommand.

use kernel::Constitution;
use std::path::PathBuf;

/// Run `xt kernel <action>`.
pub fn run(args: &[String]) -> i32 {
    let action = args.first().map(String::as_str).unwrap_or("check");
    match action {
        "check" => check(),
        "load"  => load(),
        other   => { eprintln!("unknown kernel action: {other}"); 1 }
    }
}

fn check() -> i32 {
    let path = PathBuf::from("kernel/kernel.cedar");
    if !path.exists() {
        eprintln!("kernel/kernel.cedar not found at {}", path.display());
        return 1;
    }
    match Constitution::load(&path) {
        Ok(c) => {
            println!("kernel ok: {}", c.origin().display());
            0
        }
        Err(e) => {
            eprintln!("kernel load failed: {e}");
            1
        }
    }
}

fn load() -> i32 {
    let path = PathBuf::from("kernel/kernel.cedar");
    match Constitution::load(&path) {
        Ok(c) => { println!("{}", c.origin().display()); 0 }
        Err(e) => { eprintln!("{e}"); 1 }
    }
}
