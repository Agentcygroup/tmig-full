use super::Emitter;
use crate::artifact::Harness;
pub struct JsonEmitter;
impl Emitter for JsonEmitter {
    fn emit(&self, h: &Harness) -> String {
        serde_json::to_string_pretty(h).unwrap_or_else(|e| format!("{{\"error\":\"{}\"}}", e))
    }
}
