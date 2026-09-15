use sdcl::{emit_phase, Phase, ALL_PHASES};
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: sdcl <phases|emit <phase> <file>|emit-all <file>>");
        return ExitCode::from(2);
    }
    match args[1].as_str() {
        "phases" => {
            for p in ALL_PHASES {
                println!("{}", p);
            }
            ExitCode::SUCCESS
        }
        "emit" if args.len() == 4 => {
            let phase = match Phase::parse(&args[2]) {
                Some(p) => p,
                None => {
                    eprintln!("unknown phase: {}", args[2]);
                    return ExitCode::from(2);
                }
            };
            let src = match std::fs::read_to_string(&args[3]) {
                Ok(s) => s,
                Err(e) => {
                    eprintln!("read {}: {}", args[3], e);
                    return ExitCode::from(2);
                }
            };
            let h = match harness_lang::Parser::new(&src).parse() {
                Ok(h) => h,
                Err(e) => {
                    eprintln!("parse: {:?}", e);
                    return ExitCode::from(1);
                }
            };
            print!("{}", emit_phase(&h, phase));
            ExitCode::SUCCESS
        }
        "emit-all" if args.len() == 3 => {
            let src = match std::fs::read_to_string(&args[2]) {
                Ok(s) => s,
                Err(e) => {
                    eprintln!("read {}: {}", args[2], e);
                    return ExitCode::from(2);
                }
            };
            let h = match harness_lang::Parser::new(&src).parse() {
                Ok(h) => h,
                Err(e) => {
                    eprintln!("parse: {:?}", e);
                    return ExitCode::from(1);
                }
            };
            for p in ALL_PHASES {
                println!("\n===== {} =====", p);
                println!("{}", emit_phase(&h, *p));
            }
            ExitCode::SUCCESS
        }
        _ => {
            eprintln!("usage: sdcl <phases|emit <phase> <file>|emit-all <file>>");
            ExitCode::from(2)
        }
    }
}
