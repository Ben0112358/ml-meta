# Repositories

All paths below are under `$ML_HOMELAB_ROOT`. Set that variable to the directory that contains these folders (the parent of `ml-meta`).

| Repository | Local path | Remote | Kind |
|------------|------------|--------|------|
| ml-infra | `$ML_HOMELAB_ROOT/ml-infra` | https://github.com/Ben0112358/ml-infra | terraform |
| ml-data | `$ML_HOMELAB_ROOT/ml-data` | https://github.com/Ben0112358/ml-data | python |
| ml-training | `$ML_HOMELAB_ROOT/ml-training` | https://github.com/Ben0112358/ml-training | python |
| ml-serving | `$ML_HOMELAB_ROOT/ml-serving` | https://github.com/Ben0112358/ml-serving | python |
| ml-ui | `$ML_HOMELAB_ROOT/ml-ui` | https://github.com/Ben0112358/ml-ui | python |
| ml-pipeline | `$ML_HOMELAB_ROOT/ml-pipeline` | https://github.com/Ben0112358/ml-pipeline | bash |
| ml-meta | `$ML_HOMELAB_ROOT/ml-meta` | https://github.com/Ben0112358/ml-meta | meta (scripts are bash) |

Non-repository directories often present under the same root (for example `data/`, `logs/`, `models/`, `configs/`) are runtime or local artifacts, not separate Git repos.

## Lint, test, and security (per repo)

These match each repository's CI. Cross-repo wrappers live in `$ML_HOMELAB_ROOT/ml-meta/scripts/`.

| Repository | Lint (check) | Test | Security (CI) |
|------------|--------------|------|----------------|
| ml-data | `black --check .`, `flake8 .` | `poetry run pytest` | Gitleaks, Trivy (HIGH/CRITICAL), CodeQL, Bandit (HIGH+), pip-audit (HIGH/CRITICAL via OSV) |
| ml-training | same | same | same |
| ml-serving | same | same | same |
| ml-ui | same | same | same |
| ml-pipeline | `shfmt -d .` (path-filtered on PR) | none | Gitleaks, Trivy (HIGH/CRITICAL) |
| ml-infra | `terraform fmt -check -recursive`, `terraform validate` (after local `terraform init`) | none (validate in lint) | Gitleaks, Trivy (HIGH/CRITICAL) |
| ml-meta | `shfmt -d .` (path-filtered on PR) | none | Gitleaks, Trivy (HIGH/CRITICAL) |

Python stage repos use Poetry on **3.13** in CI. Dependabot opens weekly grouped PRs for pip and GitHub Actions (python repos) or Actions only (bash/terraform/meta). For a fuller security reference (Trivy, Opengrep), see sibling repo `llm-decision-spec` under `$ML_HOMELAB_ROOT`.

If `lint-all` reports `NEEDS-INIT` for ml-infra, run `terraform init` in that repo (stale or missing `.terraform` modules). CI runs init before validate on every PR.

Cross-repo git helpers:

```bash
bash scripts/checkout-main-all.sh   # all repos ready → checkout main everywhere
bash scripts/pull-all.sh            # all on main → fetch and pull
bash scripts/sync-all.sh            # checkout-main-all then pull-all
bash scripts/cleanup-merged.sh      # report merged local branches (see workflows.md)
```

Run lint, test, and status from ml-meta:

```bash
cd "$ML_HOMELAB_ROOT/ml-meta"
bash scripts/lint-all.sh
bash scripts/test-all.sh
bash scripts/status-all.sh
bash scripts/poetry-lock-and-sync-all.sh
```

Optional repo filter: pass one or more repo names after flags, for example `bash scripts/lint-all.sh ml-data ml-training`. `poetry-lock-and-sync-all.sh` defaults to the four python stage repos only.
