# ml-meta

Overview and development control plane for the modular ML pipeline. Pipeline repositories are independent Git checkouts under `$ML_HOMELAB_ROOT`:

```
ml-infra → ml-data → ml-training → ml-serving → ml-ui
```

Orchestration: [`ml-pipeline`](https://github.com/Ben0112358/ml-pipeline) (`bash execute.sh <project> prod|dev`).

## Documentation

Start at [docs/README.md](docs/README.md):

- [Architecture](docs/architecture.md)
- [Repositories](docs/repositories.md)
- [Conventions](docs/conventions.md)
- [Workflows](docs/workflows.md)
- [New project checklist](docs/new-project.md)

Agent-oriented rules: [AGENTS.md](AGENTS.md).

## Cross-repo scripts

From this repository:

```bash
bash scripts/status-all.sh
bash scripts/lint-all.sh          # black/flake8, shfmt, terraform fmt
bash scripts/lint-all.sh --fix
bash scripts/test-all.sh
bash scripts/poetry-lock-and-sync-all.sh   # poetry lock + sync in python stage repos
bash scripts/checkout-main-all.sh
bash scripts/pull-all.sh
bash scripts/sync-all.sh              # checkout-main-all + pull-all
bash scripts/branch-all.sh my-feature ml-data ml-training
bash scripts/cleanup-merged.sh    # report merged branches; --delete to remove
bash scripts/scan-staged.sh       # flag secrets or artifacts in staged changes
bash scripts/ml.sh status         # also path, term, open, task; see docs/workflows.md
```

Optional filter: append repo names (`ml-data`, `ml-training`, ...).

## Cursor skills

With this folder as the workspace root, use skills under `.cursor/skills/` (for example `/status-all`, `/branch-all`, `/checkout-main-all`, `/pull-all`, `/check-all`, `/poetry-lock-and-sync-all`, `/add-all`, `/unstage-selected`, `/commit-all-command`, `/push-all-command`, `/pr-desc-all`, `/cleanup-merged`, `/new-project`, `/ml`). `ml open` puts this repo first in a multi-root window so those skills stay available.

## Stage repos

| Repo | Role |
|------|------|
| [ml-infra](https://github.com/Ben0112358/ml-infra) | Terraform, paths, docker network |
| [ml-data](https://github.com/Ben0112358/ml-data) | Ingest and clean data |
| [ml-training](https://github.com/Ben0112358/ml-training) | Train models |
| [ml-serving](https://github.com/Ben0112358/ml-serving) | HTTP serving |
| [ml-ui](https://github.com/Ben0112358/ml-ui) | UI |

Each stage README has run instructions for manual mode.
