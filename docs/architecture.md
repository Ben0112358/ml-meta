# Architecture

## Pipeline stages

Data flows through five stage repositories in order:

```
ml-infra → ml-data → ml-training → ml-serving → ml-ui
```

Each stage has its own Git repository and can be developed or run in isolation. End-to-end runs are orchestrated by `ml-pipeline`.

## Control and documentation repos

| Repository | Role |
|------------|------|
| `ml-pipeline` | Runs the full pipeline: prepares repos, applies infra, composes each stage |
| `ml-meta` | Documents the ecosystem and provides cross-repo scripts and skills |

## Environment root

All stage code resolves paths from `ML_HOMELAB_ROOT`. That directory is the parent of every pipeline repository (for example `$ML_HOMELAB_ROOT/ml-data`).

In pipeline mode, `ml-infra` Terraform outputs whose names match `^[A-Z_]+$` are written to:

```
$ML_HOMELAB_ROOT/.terraform_envs
```

Docker Compose files in each stage load that file via `env_file`. Python stages read the same variables through each package's `config.py`, typically as `Path(os.environ["ML_HOMELAB_ROOT"]) / <relative_dir>`.

## Orchestration (ml-pipeline)

`execute.sh` is the **end-to-end integration test** for the modular pipeline: infra through UI in one disposable run. Per-repo pytest and lint cover units; this script validates cross-repo behavior together.

Entry point (from `$ML_HOMELAB_ROOT/ml-pipeline`):

```bash
export ML_HOMELAB_ROOT=/path/to/parent-of-ml-meta   # if not already set
bash execute.sh <project_name> <prod|dev>
```

| Mode | Role |
|------|------|
| **dev** | **Local integration test** — `setup.sh` copies your sibling checkouts from `$ML_HOMELAB_ROOT/<repo>` (feature-branch state on disk). Run before merging related PRs. |
| **prod** | **Main integration test** — `setup.sh` clones each stage repo's remote **`main`**. Simulates "only merged code exists"; can fail until every related PR is on `main`. |

Script flags stay `dev` and `prod`; in prose you can read them as **local-run** vs **main-run**. Neither mode is a long-lived dev environment or production SLO tier.

Ports for serving and UI are derived from `md5("${PROJECT}_${MODE}")`: serving uses the base port, UI uses base + 1.

## Cross-repo coupling

The default boundary is one repository per stage. One explicit exception:

- **ml-serving** may mount `$ML_HOMELAB_ROOT/ml-training` and install training code in non-prod Docker builds so serving can load models defined in training.

Changes that alter model loading or training artifacts should land in **ml-training** and **ml-serving** together, in that order.

## Atomicity

There is no single commit or single PR across repositories. The **main-run** (`prod`) integration test composes each stage's `main` independently, so mismatched merges can produce a broken pipeline until all related PRs are merged. Use the **local-run** (`dev`) integration test to validate a cross-repo feature from local checkouts before merging.

Recommended merge order when a feature spans multiple repos:

```
ml-infra → ml-data → ml-training → ml-serving → ml-ui → ml-pipeline
```

Document dependencies in PR descriptions when one repo relies on another.
