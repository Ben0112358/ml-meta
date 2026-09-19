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

## Lint and test (per repo)

These match each repository's CI. Cross-repo wrappers live in `$ML_HOMELAB_ROOT/ml-meta/scripts/`.

| Repository | Lint (check) | Test |
|------------|--------------|------|
| ml-data | `black --check .`, `flake8 .` | `poetry run pytest` |
| ml-training | same | same |
| ml-serving | same | same |
| ml-ui | same | same |
| ml-pipeline | `shfmt -d .` | none |
| ml-infra | `terraform fmt -check -recursive`, `terraform validate` (after local `terraform init`) | none (validate in lint) |

If `lint-all` reports `NEEDS-INIT` for ml-infra, run `terraform init` in that repo (stale or missing `.terraform` modules). CI runs init before validate on every PR.
| ml-meta | `shfmt -d .` (this repo's scripts) | none |

Run everything from ml-meta:

```bash
cd "$ML_HOMELAB_ROOT/ml-meta"
bash scripts/lint-all.sh
bash scripts/test-all.sh
bash scripts/status-all.sh
```

Optional repo filter: pass one or more repo names after flags, for example `bash scripts/lint-all.sh ml-data ml-training`.
