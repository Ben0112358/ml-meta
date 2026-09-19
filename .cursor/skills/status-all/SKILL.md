---
name: status-all
description: Run ml-meta scripts/status-all.sh across pipeline repositories and summarize branch, ahead/behind, and working tree state. Use when the user asks for status-all, cross-repo git status, or runs /status-all.
disable-model-invocation: true
---

# status-all

## Instructions

1. From `$ML_HOMELAB_ROOT/ml-meta`, run:
   ```bash
   bash scripts/status-all.sh
   ```
2. If the user named specific repos, append them: `bash scripts/status-all.sh ml-data ml-training`.
3. Do not modify any repository.

## Report

One line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md). Do not paste the raw script output.

```text
ml-data    OK         main, clean
ml-meta    DIRTY      1 unstaged, 20 untracked
unchanged: ml-infra, ml-training, ml-serving, ml-ui, ml-pipeline

6 clean, 1 dirty, 0 ahead of upstream
```

Call out anything actionable: dirty trees, branches ahead or behind upstream, missing checkouts.
