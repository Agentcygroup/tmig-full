# Security Policy

## Reporting a vulnerability

Open a private security advisory:
https://github.com/Agentcygroup/tmig-full/security/advisories/new

Do **not** open a public issue for security reports.

Include the affected commit or tag, a minimal reproducer, and impact.

## Dependabot findings

This repo pins several dependencies for build reproducibility and
cross-package compatibility (tensorflow, keras, numpy, torch, etc).
Dependabot alerts against those pins are acknowledged and will be addressed
when an upgrade path exists that does not break the pinned set. See
`requirements*.txt` for the split between core, redteam, orchestration,
and mpi extras.
