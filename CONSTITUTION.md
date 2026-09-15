# Constitution

## The kernel defines exactly five things

Entity · Op · Lineage · Receipt · Constitution

Every conforming extension declares its entities, ops, and policy in
`extensions/<domain>/`. `kernel/check.sh` validates conformance; a
non-conforming extension fails the pre-push gate.

## Domains in this constitution

detection, segmentation, llms, embeddings, multimodal, audio, video,
diffusion, 3d, rl, gnn, symbolic, forecasting, robotics, control,
hybrids, **layoutlm** (proof of life).

## Invariants

- P1 Entity ids are content-addressed
- P2 Every Op is policy-checked before execution
- P3 Every Op that runs leaves a Receipt
- P4 Lineage is acyclic and total
- P5 The Constitution governs its own extensions
