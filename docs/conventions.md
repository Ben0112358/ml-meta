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

- Python 3.12+
- Poetry for dependencies
- Black and flake8, line length **79** (configured in each repo's `pyproject.toml`)
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
