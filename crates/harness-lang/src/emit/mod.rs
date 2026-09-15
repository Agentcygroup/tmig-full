pub mod json;
pub mod shell;
pub mod source;
use crate::artifact::Harness;
pub use json::JsonEmitter;
pub use shell::ShellEmitter;
pub use source::SourceEmitter;
pub trait Emitter {
    fn emit(&self, h: &Harness) -> String;
}
