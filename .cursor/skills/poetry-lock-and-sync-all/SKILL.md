---
name: poetry-lock-and-sync-all
description: Run poetry lock and poetry sync --no-interaction in each python stage repo (ml-data, ml-training, ml-serving, ml-ui). Use after changing pyproject.toml Python bounds or dependencies, or when the user runs /poetry-lock-and-sync-all.
disable-model-invocation: true
---

# poetry-lock-and-sync-all

Wraps `scripts/poetry-lock-and-sync-all.sh`. Only **python** stage repositories are processed.

## Instructions

1. Run from ml-meta:
   ```bash
   cd "$ML_HOMELAB_ROOT/ml-meta"
   bash scripts/poetry-lock-and-sync-all.sh
   ```
2. Use **Python 3.13** locally (same band as `pyproject.toml`: `>=3.13,<3.14`). If `poetry lock` fails, fix dependency bounds in that repo and retry.
3. Optional: `--dry-run` or a repo filter (python repos only; others are **SKIPPED**).
4. Sets `POETRY_KEYRING_ENABLED=false` when unset (avoids keyring errors in headless environments).

## Report

One line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

```text
ml-data      OK   lock + sync
ml-training  OK   lock + sync
ml-serving   FAIL poetry lock
ml-ui        OK   lock + sync

3 ok, 1 failed, 0 skipped. Next: fix ml-serving pyproject.toml and re-run
```

Non-python repos in a filter list:

```text
ml-infra     SKIPPED   not a python repo
```

After success on all four, run `/check-all` or commit updated `poetry.lock` files with `/add-all`.
