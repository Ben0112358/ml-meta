# Conventions

## Terminology

- **Pipeline repositories** — the seven Git repositories managed by ml-meta scripts: `ml-infra`, `ml-data`, `ml-training`, `ml-serving`, `ml-ui`, `ml-pipeline`, and `ml-meta`.
- **Stage repositories** — the five runtime stages from infra through UI (`ml-infra` … `ml-ui`).
- **`ML_HOMELAB_ROOT`** — environment variable for the directory that contains those repositories as sibling folders. The name of that directory on disk is arbitrary; docs and scripts refer only to the variable and paths like `$ML_HOMELAB_ROOT/ml-data`.

## Project layout (python stages)

Each of `ml-data`, `ml-training`, `ml-serving`, and `ml-ui` follows:

```
docker-compose.<project>.yaml
Dockerfile.<project>
src/<package_name>/<project>/
tests/
pyproject.toml
```

Package names: `ml_data`, `ml_training`, `ml_serving`, `ml_ui`.

Reference implementation: `dummy_project` in each stage repo. Production example: `investing_allocation_optimizer`.

## Configuration

Each stage exposes a `config.py` that reads environment variables (including `ML_HOMELAB_ROOT`) and exposes paths for data, models, and logs.

## Python formatting and lint

- Python **3.13** band: `>=3.13,<3.14` in each stage repo's `pyproject.toml`
- Poetry for dependencies; use `poetry install --sync` to match the lockfile
- Stage repos run **lint**, **test**, and **security** GitHub workflows on pull requests (and on push to `main` where configured)
- Every pipeline repo has `.github/workflows/grok-review.yml`. A pull request opened or reopened runs the copy of that file from the pull request and notifies a review webhook. Later pushes do not. A `/grok review` comment from `Ben0112358` runs the copy on the default branch. `contains` matches that phrase without regard to case. The job does not check out the pull request. Each repo needs secrets `GROK_REVIEW_WEBHOOK_URL` and `GROK_REVIEW_WEBHOOK_AUTH`. A run where those secrets are absent, including Dependabot and fork pull requests, skips the notification and exits successfully.
- Every pipeline repo has `.github/workflows/grok-housekeeping.yml`. A daily schedule starts the job at a fixed UTC slot. The job POSTs `repo`, `mode`, `sha`, and `event` to a housekeeping webhook only when the UTC day number since 1970-01-01 is divisible by 3, so about one day in three calls the webhook. On those days the mode rotates through `security`, `docs`, `errors`, `dependencies`, `style`, and `tests`, and each mode returns every 18 days. A scheduled run on any other day exits before the webhook. `workflow_dispatch` offers those same modes and runs on any day. UTC slots are ml-data 03:37, ml-infra 04:07, ml-meta 04:37, ml-pipeline 05:07, ml-serving 05:37, ml-training 06:07, and ml-ui 06:37; only that minute and hour differ between copies. The job does not check out the repo and does not open pull requests. The housekeeper does that, in small focused changes, with its own credentials. Each repo needs secrets `GROK_HOUSEKEEPER_WEBHOOK_URL` and `GROK_HOUSEKEEPER_WEBHOOK_AUTH` (the full Authorization header value). A run with those secrets unset fails when it reaches the webhook.
- **Security CI policy (all pipeline repos):** jobs fail on **HIGH/CRITICAL** findings where the tool supports severity (Trivy, Bandit `-lll`, pip-audit via OSV severity). Gitleaks always fails on detected secrets. Fix or bump dependencies for actionable HIGH issues; lower severities are reported in logs but do not block merge.
- Black line length **79** in each repo's `pyproject.toml`; flake8 **79** via `.flake8` (`max-line-length`)
- Tests with pytest under `tests/`

## Bash (ml-pipeline, ml-meta scripts)

- `set -euo pipefail`
- Tabs for indentation in shell scripts (match ml-pipeline)
- Checked with `shfmt -d .` in CI

## Terraform (ml-infra)

- `terraform fmt -check -recursive` on pull requests
- `terraform validate` after `terraform init`

## Naming projects

Use a single snake_case `<project_name>` across all touched repos: same folder name under `src/.../<project_name>/`, and matching `Dockerfile.<project_name>` and `docker-compose.<project_name>.yaml`.

## Cross-repo changes

Prefer small PRs per repository. When behavior spans stages, merge in pipeline order (see [architecture.md](architecture.md)) and note dependencies in PR text.
