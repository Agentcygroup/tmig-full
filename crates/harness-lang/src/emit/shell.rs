use super::Emitter;
use crate::artifact::*;
pub struct ShellEmitter;
impl Emitter for ShellEmitter {
    fn emit(&self, h: &Harness) -> String {
        let mut s = String::new();
        s.push_str("#!/usr/bin/env bash\nset -euo pipefail\n");
        s.push_str(&format!("# harness: {}\n", h.id.0));
        s.push_str(&format!("# nonclaim: {}\n", h.nonclaim.as_str()));
        for c in &h.cites {
            s.push_str(&format!("# cite: {} :: {}\n", c.instrument, c.clause));
        }
        for i in &h.inputs {
            match i.kind {
                InputKind::File => s.push_str(&format!("test -f {}\n", i.body)),
                InputKind::Stdin => s.push_str(&format!("printf '%s' {} | \\\n", i.body)),
                InputKind::Env => s.push_str(&format!("export {}\n", i.body)),
            }
        }
        s.push_str(&h.target.body);
        s.push('\n');
        s
    }
}
