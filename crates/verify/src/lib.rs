use schema::{NonClaim, Schema};
pub struct Shell;
impl Schema for Shell {
    fn name(&self) -> &str {
        "shell"
    }
    fn non_claims(&self) -> &[NonClaim] {
        const NC: &[NonClaim] = &[NonClaim {
            id: String::new(),
            statement: String::new(),
            rationale: String::new(),
        }];
        NC
    }
    fn verify(&self, v: &str) -> Result<(), String> {
        if v.is_empty() {
            Err("empty".into())
        } else {
            Ok(())
        }
    }
}
pub struct Checks;
impl Schema for Checks {
    fn name(&self) -> &str {
        "checks"
    }
    fn non_claims(&self) -> &[NonClaim] {
        const NC: &[NonClaim] = &[NonClaim {
            id: String::new(),
            statement: String::new(),
            rationale: String::new(),
        }];
        NC
    }
    fn verify(&self, v: &str) -> Result<(), String> {
        if std::path::Path::new(v).is_dir() {
            Ok(())
        } else {
            Err("not a dir".into())
        }
    }
}
pub fn builtins() -> Vec<Box<dyn Schema>> {
    vec![Box::new(Shell), Box::new(Checks)]
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn register_all() {
        let mut r = schema::Registry::new();
        for b in builtins() {
            r.register(b).unwrap();
        }
        assert!(r.get("shell").is_some());
    }
}
