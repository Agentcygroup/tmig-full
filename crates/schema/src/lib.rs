pub struct NonClaim {
    pub id: String,
    pub statement: String,
    pub rationale: String,
}
pub trait Schema: Send + Sync {
    fn name(&self) -> &str;
    fn non_claims(&self) -> &[NonClaim];
    fn verify(&self, v: &str) -> Result<(), String>;
}
#[derive(Default)]
pub struct Registry {
    schemas: std::collections::BTreeMap<String, Box<dyn Schema>>,
}
#[derive(Debug)]
pub enum Err {
    NoNonClaims,
    Already,
}
impl Registry {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn register(&mut self, s: Box<dyn Schema>) -> Result<(), Err> {
        if s.non_claims().is_empty() {
            return Err(Err::NoNonClaims);
        }
        if self.schemas.contains_key(s.name()) {
            return Err(Err::Already);
        }
        self.schemas.insert(s.name().into(), s);
        Ok(())
    }
    pub fn get(&self, n: &str) -> Option<&dyn Schema> {
        self.schemas.get(n).map(|b| &**b)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    struct E;
    impl Schema for E {
        fn name(&self) -> &str {
            "e"
        }
        fn non_claims(&self) -> &[NonClaim] {
            &[]
        }
        fn verify(&self, _: &str) -> Result<(), String> {
            Ok(())
        }
    }
    #[test]
    fn refuses_empty() {
        let mut r = Registry::new();
        assert!(matches!(r.register(Box::new(E)), Err(Err::NoNonClaims)));
    }
}
