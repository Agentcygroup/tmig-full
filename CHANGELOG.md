# Changelog

Format follows Keep a Changelog (https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Repository hygiene: CI, CodeQL, Dependabot grouping, security policy,
  contributing guide, CODEOWNERS, issue/PR templates.

### Changed
- `requirements.txt` restored to full set from `629ae2b`; non-coexisting
  packages split into `requirements-redteam.txt`,
  `requirements-orchestration.txt`, `requirements-mpi.txt`.
  `netifaces` and `requests-fuzzer` dropped; `pyOpenSSL` bumped to `>=24.3`.

### Removed
- n/a
