# Sovereign infra

Infrastructure-as-code where the code lives on the machine it describes,
the reconciler runs on the same machine, and the trust anchor is a
signature — not a remote control plane.

## The one idea

Every other IaC system separates three things:

    desired state        (declared in a remote repo)
    reconciler           (runs on a control plane you rent)
    observed state       (cached in a state file you own)

This system collapses all three onto the host:

    desired state        = infra/hosts/<host>.yaml       (signed)
    reconciler           = infra/bin/reconcile           (local)
    observed state       = infra/state/<host>.observed   (recomputed)

Convergence is answered by comparing the signed description to observed
state on the same box, with no network dependency. The network is only
needed to fetch the recipe tarball the first time, or when a human
explicitly asks to sync.

## Trust model

Every host description is signed with a minisign key. `reconcile`
refuses to act on an unsigned or modified description. The signature is
what binds "this is what we said this host should be" to "this is what
we observe it to be." There is no bearer token, no cloud API, no
OIDC dance at reconcile time.

## Cedar policy

Every unit of work the reconciler wants to perform is first checked
against `infra/policy.cedar` — the same Cedar engine already in
`crates/policy`. A recipe that tries to run `python -m http.server`
or modify `/System` never executes: the policy denies it before
the reconciler's exec layer sees it.

## Layers

    infra/
      hosts/          per-host YAML — desired state
      recipes/        named recipes — reusable bundles of units
      units/          atomic operations — install, service, file, exec
      state/          observed state — recomputed on every reconcile
      receipts/       signed receipts — every reconcile leaves one
      bin/            the reconciler
      policy.cedar    what a unit is allowed to do
      check.sh        the layer's own test — exits 0 on success

## Relationship to the rest of tmig-full

- `crates/policy` — used as the policy engine
- `xt release` — used to package recipes into signed tarballs
- `scripts/local-verify.sh` — calls `infra/check.sh` as one stage
- `scripts/githooks/pre-push` — gates every push on `check.sh`

Nothing in `infra/` depends on GitHub, on a running tmig-full binary, or
on this machine's specific architecture. It is host-agnostic. The only
thing that varies per host is `infra/hosts/<hostname>.yaml`.
