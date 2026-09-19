---
name: checkout-main-all
description: Check out main on all pipeline repositories only when every target repo has a clean working tree and no unpushed commits. Use before pull-all after merged PRs or when the user runs /checkout-main-all.
disable-model-invocation: true
---

# checkout-main-all

Wraps `scripts/checkout-main-all.sh`. All-or-nothing: if any repo is not ready, **no** checkouts run.

## Instructions

1. Run:
   ```bash
   cd "$ML_HOMELAB_ROOT/ml-meta"
   bash scripts/checkout-main-all.sh
   ```
2. If blocked, list each `repo: reason` (dirty, unpushed, missing main, etc.) and suggest `/status-all` or commit/stash/push as appropriate.
3. On success, every target repo is on `main`. Does not fetch or pull; run `/pull-all` next.
4. Optional: `--dry-run` or repo filter `[repos...]`.

## Report

One line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

When blocked, make clear that **nothing was checked out**:

```text
BLOCKED - no repo was changed
ml-meta      BLOCKED   dirty working tree
ml-data      READY
...

1 blocker. Next: commit, stash, or push in ml-meta, then re-run.
```

On success:

```text
ml-infra     OK   switched to main
ml-data      OK   already on main
...

7 on main. Next: /pull-all
```
