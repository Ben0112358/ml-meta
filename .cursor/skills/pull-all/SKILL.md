---
name: pull-all
description: Fetch and fast-forward pull main on all pipeline repositories when every repo is on main and ready for pull. Use after checkout-main-all or when the user runs /pull-all.
disable-model-invocation: true
---

# pull-all

Wraps `scripts/pull-all.sh`. All-or-nothing: if any repo is not on `main` or not ready, **no** pulls run.

## Instructions

1. Run:
   ```bash
   cd "$ML_HOMELAB_ROOT/ml-meta"
   bash scripts/pull-all.sh
   ```
2. If blocked, report blockers. Common fix: run `/checkout-main-all` first when repos are still on a feature branch. Readiness ignores allowlisted untracked artifacts only (`pip-audit.json`, SARIF/installer names in [workflows.md](../../docs/workflows.md#git-readiness-checkout-main-all--pull-all)); tracked edits and other untracked files still block.
3. Optional: `--dry-run` or repo filter.

## Report

One line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

When blocked, state that **nothing was pulled**:

```text
BLOCKED - no repo was pulled
ml-ui   BLOCKED   not on main

Next: /checkout-main-all
```

On success, say whether each repo actually moved:

```text
ml-data      OK   updated
ml-training  OK   already up to date
...

7 ok, 0 failed. Next: /cleanup-merged
```

Post-merge sequence: `/status-all` → `/checkout-main-all` → `/pull-all` → `/cleanup-merged`.
