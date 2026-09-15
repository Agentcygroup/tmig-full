# extras/vision

Vendored vision stack (`torch`, `torchvision`). Pinned to versions known-vulnerable
upstream with no clean upgrade path yet — the numpy 2.x migration is a prerequisite.

Kept OUT of the Dependabot scan tree on purpose. Track manually.

Prereq for `torch>=2.6.0` (CVE-2025-32434, critical RCE via `torch.load`):
  - numpy 2.x migration across the whole `requirements.txt`
  - `mlflow` 3.x (unblocks `pyarrow>=20`, which unblocks `lxml` 6.x)
