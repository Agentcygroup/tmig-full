# Open items

Known unimplemented paths. Every `unimplemented!`, `todo!`, `Unsupported`,
or `unreachable!` in `crates/` must be listed here with a reason.

| File | Token | Reason |
|---|---|---|
| crates/harness-lang/src/execute.rs | Unsupported | `TargetKind::Function` requires a host runner; not yet provided |
| crates/harness-lang/tests/wasm_target.rs | #[ignore] | Real `.wasm` fixture not yet added |

## docs

Public items missing rustdoc comments. `scripts/tests/rustdoc.sh` counts
them and reports. Tighten the check to fail when this list is empty.

- `crates/harness-lang/src/parser.rs` — `Parser::parse`, `Parser::new`, `ParseError`
- `crates/schema/src/lib.rs` — crate, `NonClaimRecord` + fields, `Schema` trait + methods, `Registry`, `Err`
- `crates/release/src/lib.rs`, `crates/release/src/hermetic.rs` — crate, module, struct + fields, associated fn, method
