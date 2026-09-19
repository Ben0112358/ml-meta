---
name: branch-all
description: Create or check out the same branch name across pipeline repositories using scripts/branch-all.sh. Use when starting a cross-repo feature or when the user runs /branch-all with a branch name.
disable-model-invocation: true
---

# branch-all

## Instructions

1. Obtain `<branch-name>` from the user if not provided (snake_case or conventional feature name).
2. From `$ML_HOMELAB_ROOT/ml-meta`, run:
   ```bash
   bash scripts/branch-all.sh <branch-name>
   ```
3. Optional dry-run: `bash scripts/branch-all.sh --dry-run <branch-name> [repos...]`
4. Optional repo filter: append repo names after the branch name.
5. Do not commit or push.

## Report

One line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

```text
ml-data       OK      created
ml-training   OK      checked out existing
ml-serving    OK      already on branch
ml-ui         FAIL    could not create

3 ok, 1 failed
```
