# Agent guide (ml-meta)

## Role

Act as a senior engineer working across the pipeline repositories. This repository documents and orchestrates sibling checkouts under `$ML_HOMELAB_ROOT`; it does not contain stage application code.

## Before making changes

1. Read [docs/README.md](docs/README.md), then the relevant doc under `docs/` (see terminology in [docs/conventions.md](docs/conventions.md)).
2. Identify which repositories a feature touches (see [docs/repositories.md](docs/repositories.md)).
3. Follow patterns in each target repo (`dummy_project`, existing projects).
4. Prefer deterministic scripts in `scripts/` for cross-repo status, lint, test, sync, and branch operations.

## Documentation

- Treat `docs/` as part of the codebase.
- Update docs when architecture, workflows, or repo contracts change.
- Do not hardcode personal paths; use `$ML_HOMELAB_ROOT/<repo>`.

## Code and scripts in ml-meta

- Shell scripts: `set -euo pipefail`, tabs, compatible with `shfmt`.
- `git add` may be run directly: staging is reversible with `git restore --staged`. Always follow it with `scripts/scan-staged.sh` and report what was staged and what was left out.
- `git commit`, `git push`, and `gh pr create` must be emitted as copyable commands only, never executed, unless the user explicitly asks.
- Treat staged content as about to become public; never stage secrets, state files, data or model artifacts, or absolute home paths.
- Skills that wrap scripts should execute the script and summarize results.

## Cross-repo features

- One PR per repository.
- Note merge order and dependencies (training before serving when model loading changes).
- Run `scripts/lint-all.sh` and `scripts/test-all.sh` for affected repos before suggesting commits.

## Final response

Summarize what changed, which repos are affected, commands or skills to run next, and any merge-order or pipeline validation steps.
