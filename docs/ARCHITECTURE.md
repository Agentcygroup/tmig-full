# Architecture

## Kernel

`crates/kernel` — five concepts as Rust types:

| Concept | File | Role |
|---|---|---|
| Entity | src/entity.rs | content-addressed id + kind + attrs |
| Op | src/op.rs | name + effect + typed inputs/outputs |
| Lineage | src/lineage.rs | acyclic parent-of graph |
| Receipt | src/receipt.rs | SHA-256 signed record of an Op that ran |
| Constitution | src/constitution.rs | cedar-policy wrapper gating every Op |

## Extensions

`extensions/<domain>/` declares ops, entities, cedar policy, and `run.rs`.
`kernel/check.sh` validates conformance; a non-conforming extension fails
the pre-push gate.

## Layers

`infra/`, `lifecycle/`, `ci/`, `dxp/`, `ix/`, `ui/`, `ux/`, `org/`,
`licensing/` — each with a `check.sh` that exits 0 on success and is
wired into `scripts/local-verify.sh`.
