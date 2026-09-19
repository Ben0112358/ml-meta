---
name: new-project
description: Scaffold a new snake_case project across ml-data, ml-training, ml-serving, and ml-ui by copying dummy_project via scripts/scaffold-project.sh. Use when adding a new pipeline project or when the user runs /new-project.
disable-model-invocation: true
---

# new-project

## Instructions

1. Read [docs/new-project.md](../../docs/new-project.md).
2. Confirm `<project_name>` with the user if not provided (snake_case, lowercase).
3. Preview when unsure:
   ```bash
   cd "$ML_HOMELAB_ROOT/ml-meta"
   bash scripts/scaffold-project.sh <project_name> --dry-run
   ```
4. Run scaffold:
   ```bash
   bash scripts/scaffold-project.sh <project_name>
   ```
5. Review diffs in all four repos. Adjust business logic; add tests under each repo's `tests/`.
6. Run:
   ```bash
   bash scripts/lint-all.sh ml-data ml-training ml-serving ml-ui
   bash scripts/test-all.sh ml-data ml-training ml-serving ml-ui
   ```
7. Remind the user to validate with `bash execute.sh <project_name> dev` from `ml-pipeline` when ready.

Do not commit or push unless the user explicitly asks.

## Report

One line per repo scaffolded, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

```text
ml-data       OK     src/ml_data/<project>/ + Dockerfile + compose
ml-training   OK     src/ml_training/<project>/ + Dockerfile + compose
ml-serving    OK     ...
ml-ui         FAIL   destination already exists

3 ok, 1 failed. Lint: 4 ok. Tests: 4 ok.
Next: implement logic and add tests, then bash execute.sh <project> dev
```

State clearly that business logic is still a copy of `dummy_project` and needs real implementation.
