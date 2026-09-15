# Contributing

## Setup

    git clone git@github.com:Agentcygroup/tmig-full.git
    cd tmig-full
    python3 -m venv venvs/main && venvs/main/bin/pip install -r requirements.txt
    cargo build --release --workspace

Optional extras (each in its own venv):
- `requirements-redteam.txt`
- `requirements-orchestration.txt`
- `requirements-mpi.txt` (needs `brew install open-mpi` first)

## Checks before opening a PR

    ./target/release/xt ci

## Commit style

Conventional commits, one logical change per commit.

## PRs

One reviewer, CI green, description includes what/why/how-verified.
