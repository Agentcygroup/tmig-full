# Invariants

Every invariant is a property a command can fail on. This file is
the index. `scripts/tests/invariants-indexed.sh` verifies the two
stay in sync. Update by running this script:

```bash
python3 scripts/regenerate-invariants.py
```

## Shell checks (`scripts/tests/*.sh`)

- `scripts/tests/cli-contracts.sh`
- `scripts/tests/commit-nonclaim.sh`
- `scripts/tests/concurrency.sh`
- `scripts/tests/coverage-by-name.sh`
- `scripts/tests/cross-target.sh`
- `scripts/tests/docs-claims.sh`
- `scripts/tests/edition-consistency.sh`
- `scripts/tests/go-xt-agree.sh`
- `scripts/tests/hooks-installed.sh`
- `scripts/tests/locked-build.sh`
- `scripts/tests/makefile-docs.sh`
- `scripts/tests/no-absolute-paths.sh`
- `scripts/tests/no-duplicate-types.sh`
- `scripts/tests/nonclaim-type-identity.sh`
- `scripts/tests/open-tracking.sh`
- `scripts/tests/resource-bounds.sh`
- `scripts/tests/rustdoc.sh`
- `scripts/tests/schema-presence.sh`
- `scripts/tests/time-bounds.sh`
- `scripts/tests/version-consistency.sh`

## Rust tests (`crates/*/tests/*.rs`)

- `adversarial.rs`
- `assertions.rs`
- `emit_all_phases.rs`
- `emit_roundtrip.rs`
- `escaping.rs`
- `execute_fail.rs`
- `execute_pass.rs`
- `forbidden_words_match_policy.rs`
- `nonempty.rs`
- `parse_errors.rs`
- `parse_missing_nonclaim.rs`
- `parse_ok.rs`
- `roundtrip.rs`
- `shape.rs`
- `smoke.rs`
- `structural.rs`
- `structure.rs`
- `wasm_target.rs`
- `workspace_members_snapshot.rs`

## CLI golden files (`tests/golden/`)

- `tests/golden/xt-policy-authorize-allow.txt`
- `tests/golden/sdcl-phases.txt`

