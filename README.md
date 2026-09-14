# tmig-full

Full workspace for `tmig` — nine crates, ten producers, eleven standards, FFI bindings for
Python / Ruby / Node / Go, and the `xt` intent-driven gate.

## Canonical digest

Every binding returns, for `"hello"`:

    2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824

Enforced by `checks/lang/02-digest-agreement.sh` under `xt ci`.

## Layout

- `checks/engines.sh` — toolchain registry
- `checks/lang/` — registry gate, digest agreement, drift
- `bindings/{python,ruby,node,go}/` — all calling `tmig_id_of` against `libffi.dylib`
- `receipts/` — xt run + freeze receipts
