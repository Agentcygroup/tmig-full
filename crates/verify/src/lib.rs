use schema::{NonClaimRecord, Schema};
pub struct Shell;
impl Schema for Shell {
    fn name(&self) -> &str {
        "shell"
    }
    fn non_claims(&self) -> &[NonClaimRecord] {
        const NC: &[NonClaimRecord] = &[NonClaimRecord {
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
    fn non_claims(&self) -> &[NonClaimRecord] {
        const NC: &[NonClaimRecord] = &[NonClaimRecord {
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
/// All built-in schemas known to this binary.
/// Each has a name, a set of non-claims, and a verifier.
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
