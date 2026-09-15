use crate::artifact::*;
use std::process::Command;
use std::sync::OnceLock;

static WASM_ENGINE: OnceLock<wasmtime::Engine> = OnceLock::new();
fn wasm_engine() -> &'static wasmtime::Engine {
    WASM_ENGINE.get_or_init(wasmtime::Engine::default)
}

#[derive(Debug)]
pub struct Outcome {
    pub harness: Ident,
    pub passed: bool,
    pub details: Vec<String>,
}

#[derive(Debug)]
pub enum RunError {
    MissingNonclaim,
    Io(std::io::Error),
    Regex(String),
}
impl From<std::io::Error> for RunError {
    fn from(e: std::io::Error) -> Self {
        RunError::Io(e)
    }
}

pub fn run(h: &Harness, workdir: &str) -> Result<Outcome, RunError> {
    if h.nonclaim.as_str().trim().is_empty() {
        return Err(RunError::MissingNonclaim);
    }
    match h.target.kind {
        TargetKind::Shell | TargetKind::Binary => run_process(h, workdir),
        TargetKind::Function => Err(RunError::Io(std::io::Error::new(
            std::io::ErrorKind::Unsupported,
            "function targets require a host",
        ))),
        TargetKind::Wasm => run_wasm(h, workdir),
    }
}

fn run_process(h: &Harness, workdir: &str) -> Result<Outcome, RunError> {
    let output = match h.target.kind {
        TargetKind::Shell => Command::new("sh")
            .arg("-c")
            .arg(&h.target.body)
            .current_dir(workdir)
            .output()?,
        TargetKind::Binary => {
            let mut parts = h.target.body.split_whitespace();
            let bin = parts.next().ok_or_else(|| {
                RunError::Io(std::io::Error::new(
                    std::io::ErrorKind::InvalidInput,
                    "empty binary",
                ))
            })?;
            let mut cmd = Command::new(bin);
            cmd.args(parts).current_dir(workdir);
            cmd.output()?
        }
        _ => unreachable!(),
    };
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let code = output.status.code().unwrap_or(-1);
    let mut details = Vec::new();
    for a in &h.assertions {
        let (ok, detail) = check_assertion(a, code, &stdout, workdir)?;
        if !ok {
            details.push(detail);
        }
    }
    Ok(Outcome {
        harness: h.id.clone(),
        passed: details.is_empty(),
        details,
    })
}

fn run_wasm(h: &Harness, workdir: &str) -> Result<Outcome, RunError> {
    let path = std::path::Path::new(workdir).join(&h.target.body);
    let module = wasmtime::Module::from_file(wasm_engine(), &path).map_err(|e| {
        RunError::Io(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            e.to_string(),
        ))
    })?;
    let mut store = wasmtime::Store::new(wasm_engine(), ());
    let instance = wasmtime::Instance::new(&mut store, &module, &[])
        .map_err(|e| RunError::Io(std::io::Error::other(e.to_string())))?;
    let ran = if let Ok(f) = instance.get_typed_func::<(), ()>(&mut store, "run") {
        f.call(&mut store, ())
            .map(|_| "run")
            .map_err(|e| e.to_string())
    } else if let Ok(f) = instance.get_typed_func::<(), ()>(&mut store, "_start") {
        f.call(&mut store, ())
            .map(|_| "_start")
            .map_err(|e| e.to_string())
    } else {
        Err("no exported run() or _start() found".to_string())
    };
    match ran {
        Ok(_) => Ok(Outcome {
            harness: h.id.clone(),
            passed: true,
            details: vec![],
        }),
        Err(e) => Ok(Outcome {
            harness: h.id.clone(),
            passed: false,
            details: vec![format!("wasm call failed: {}", e)],
        }),
    }
}

fn check_assertion(
    a: &Assertion,
    code: i32,
    stdout: &str,
    workdir: &str,
) -> Result<(bool, String), RunError> {
    Ok(match a {
        Assertion::Exit(n) => (code == *n, format!("exit: want {}, got {}", n, code)),
        Assertion::StdoutContains(s) => {
            let ok = stdout.contains(s);
            (ok, format!("stdout contains {:?}: {}", s, ok))
        }
        Assertion::StdoutMatches(pat) => {
            let re = regex::Regex::new(pat).map_err(|e| RunError::Regex(e.to_string()))?;
            let ok = re.is_match(stdout);
            (ok, format!("stdout matches {:?}: {}", pat, ok))
        }
        Assertion::FileExists(p) => {
            let path = std::path::Path::new(workdir).join(p);
            let ok = path.exists();
            (ok, format!("file exists {:?}: {}", p, ok))
        }
    })
}
