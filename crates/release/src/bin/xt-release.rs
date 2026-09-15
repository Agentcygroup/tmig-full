use release::HermeticEnv;
use std::path::PathBuf;

fn main() {
    let mut repo = None;
    let mut out = None;
    let mut args = std::env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "--repo" => repo = args.next().map(PathBuf::from),
            "--out"  => out  = args.next().map(PathBuf::from),
            _ => {}
        }
    }
    let repo = repo.unwrap_or_else(|| std::env::current_dir().unwrap());
    let out  = out.unwrap_or_else(|| repo.join("out"));
    let env = HermeticEnv::capture(&repo, &out).expect("capture");
    let tarball = env.tarball(&repo).expect("tarball");
    println!("{}", tarball.display());
}
