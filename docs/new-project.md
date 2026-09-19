# Adding a new project

A **project** is the cross-repo unit of work: the same `<project_name>` in `ml-data`, `ml-training`, `ml-serving`, and usually `ml-ui`. Optional changes in `ml-infra` or `ml-pipeline` depend on the feature.

## Checklist

1. Choose `<project_name>` (snake_case).
2. **ml-data** — copy `src/ml_data/dummy_project` to `src/ml_data/<project_name>/`, add `Dockerfile.<project_name>` and `docker-compose.<project_name>.yaml`, add tests under `tests/`.
3. **ml-training** — same pattern under `src/ml_training/<project_name>/`.
4. **ml-serving** — same under `src/ml_serving/<project_name>/`. If serving imports training code, follow `investing_allocation_optimizer` compose and Dockerfile patterns.
5. **ml-ui** — same under `src/ml_ui/<project_name>/`.
6. **ml-infra** — only if new directories, networks, or Terraform outputs are required.
7. **ml-pipeline** — only if orchestration or stage scripts need changes.
8. Run from ml-meta:
   ```bash
   bash scripts/lint-all.sh ml-data ml-training ml-serving ml-ui
   bash scripts/test-all.sh ml-data ml-training ml-serving ml-ui
   ```
9. Validate end-to-end: `bash execute.sh <project_name> dev` from ml-pipeline.
10. Open one PR per repository; merge in order from [architecture.md](architecture.md).

## Reference files

Use `dummy_project` in each repo for minimal structure. For a richer example, compare `investing_allocation_optimizer` across the four python stages.

## Scaffold script

From `$ML_HOMELAB_ROOT/ml-meta`:

```bash
bash scripts/scaffold-project.sh <project_name> --dry-run
bash scripts/scaffold-project.sh <project_name>
```

## Skill

The `/new-project` skill runs the scaffold script and reminds you to add tests and run lint-all. Review diffs before committing.
