# Polyglot merge gate

The land decision is fail-closed and requires three independent artifacts from the current commit range:

1. `delta-ranked.json` — ranked `{Δ}` generated from `git diff BASE...HEAD`.
2. `harness.json` — required language/harness checks all `PASS`, with every changed executable language covered.
3. `ledger-grade.json` — grade over current-run ledger rows; any required `FAIL` or `SKIP` blocks land.

`merge_gate.py evaluate` emits `ALLOW_LAND` only if the highest-risk delta's grade threshold is met and the harness covers every required changed language. Control-plane changes are ranked `critical` and require ledger grade `A`.

The output `land-decision.json` binds the three input digests and has its own SHA-256 decision digest. It is evidence of the gate decision, not an external certification.
