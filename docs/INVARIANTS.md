# Invariants

Every invariant MUST be enforced by a command that can fail (RFC 2119).
An invariant that SHOULD hold but is not enforced MUST appear in OPEN.md.

`scripts/tests/invariants-indexed.sh` MUST keep this file in sync.
Regenerate with `python3 scripts/regenerate-invariants.py`.

## Shell checks (`scripts/tests/*.sh`)

- `scripts/tests/cli-contracts.sh`
- `scripts/tests/commit-nonclaim.sh`
- `scripts/tests/concurrency.sh`
- `scripts/tests/coverage-by-name.sh`
- `scripts/tests/cross-target.sh`
- `scripts/tests/docs-claims.sh`
- `scripts/tests/edition-consistency.sh`
- `scripts/tests/emergence-covered.sh`
- `scripts/tests/go-xt-agree.sh`
- `scripts/tests/hooks-installed.sh`
- `scripts/tests/industries-covered.sh`
- `scripts/tests/locked-build.sh`
- `scripts/tests/makefile-docs.sh`
- `scripts/tests/no-absolute-paths.sh`
- `scripts/tests/no-duplicate-types.sh`
- `scripts/tests/nonclaim-type-identity.sh`
- `scripts/tests/open-tracking.sh`
- `scripts/tests/resource-bounds.sh`
- `scripts/tests/rfc2119.sh`
- `scripts/tests/rustdoc.sh`
- `scripts/tests/schema-presence.sh`
- `scripts/tests/time-bounds.sh`
- `scripts/tests/usd-actions-covered.sh`
- `scripts/tests/usd-behaviors-covered.sh`
- `scripts/tests/version-consistency.sh`

## Standards checks (`scripts/tests/standards/*.sh`)

- `scripts/tests/standards/acm-avoid-harm.sh`
- `scripts/tests/standards/acm-honesty.sh`
- `scripts/tests/standards/bcs-competence.sh`
- `scripts/tests/standards/coe-transparency.sh`
- `scripts/tests/standards/eu-ai-act-prohibited.sh`
- `scripts/tests/standards/gdpr-principles.sh`
- `scripts/tests/standards/ieee-7000-values.sh`
- `scripts/tests/standards/ieee-7001-transparency.sh`
- `scripts/tests/standards/ieee-7002-privacy.sh`
- `scripts/tests/standards/iso-25010-quality.sh`
- `scripts/tests/standards/iso-27001-security.sh`
- `scripts/tests/standards/iso-29119-testing.sh`
- `scripts/tests/standards/iso-42001-monitor.sh`
- `scripts/tests/standards/iso-42001-transparency.sh`
- `scripts/tests/standards/iso-9001-quality.sh`
- `scripts/tests/standards/nist-govern.sh`
- `scripts/tests/standards/nist-measure.sh`
- `scripts/tests/standards/nist-ssdf.sh`
- `scripts/tests/standards/oecd-accountability.sh`
- `scripts/tests/standards/oecd-risk.sh`
- `scripts/tests/standards/se-code-product.sh`
- `scripts/tests/standards/se-code-profession.sh`
- `scripts/tests/standards/uk-ai-principles.sh`
- `scripts/tests/standards/unesco-eia.sh`
- `scripts/tests/standards/wcag-accessibility.sh`

## Rust tests (`crates/*/tests/*.rs`)

- `adversarial.rs`
- `assertions.rs`
- `emergence.rs`
- `emit_all_phases.rs`
- `emit_roundtrip.rs`
- `escaping.rs`
- `execute_fail.rs`
- `execute_pass.rs`
- `forbidden_words_match_policy.rs`
- `nonempty.rs`
- `parse.rs`
- `parse_errors.rs`
- `parse_missing_nonclaim.rs`
- `parse_ok.rs`
- `roundtrip.rs`
- `shape.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `smoke.rs`
- `structural.rs`
- `structure.rs`
- `wasm_target.rs`
- `workspace_members_snapshot.rs`

## CLI golden files (`tests/golden/`)

- `tests/golden/xt-policy-authorize-allow.txt`
- `tests/golden/sdcl-phases.txt`

