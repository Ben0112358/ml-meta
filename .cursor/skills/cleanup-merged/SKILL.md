---
name: cleanup-merged
description: Report or remove local branches whose work is already on origin/main across pipeline repositories, including squash merges. Use after PRs are merged, when repos may still be on a feature branch, or when the user runs /cleanup-merged.
disable-model-invocation: true
---

# cleanup-merged

Wraps `scripts/cleanup-merged.sh`. The script classifies branches; do not judge merged state yourself.

## When to use

After all PRs are merged. Repos may still be checked out on the same feature branch name (for example `add-orchestration-support`). That is expected.

Recommended order: `/checkout-main-all` → `/pull-all` → `/cleanup-merged` (report, then `--delete` if desired).

## Instructions

1. Always report first:
   ```bash
   cd "$ML_HOMELAB_ROOT/ml-meta"
   bash scripts/cleanup-merged.sh
   ```
   - Fetches each repo, prints `was on: <branch>`.
   - Classifies every local branch against **`origin/main` after fetch`** (not stale local `main`).
   - **Dirty repos**: still classified; line `dirty — report only`. No checkout or delete in report mode.
   - Output: `WOULD DELETE (<signal>)` or `KEEP (not merged)`.

2. Signals:
   - `ancestry` — branch tip is an ancestor of the merge target
   - `squash` — branch tree matches a squash commit on the merge target (patch id)
   - `pr-merged` — GitHub merged PR for the branch (only with `--gh`)

3. Delete only after user confirms and working trees are clean:
   ```bash
   bash scripts/cleanup-merged.sh --delete
   ```
   Dirty repos are **refused** for delete; clean repos checkout `main`, fast-forward toward `origin/main`, then delete merged branches.

4. Scope: append repo names to limit targets.

5. If `KEEP` but PR was merged: run `bash scripts/cleanup-merged.sh --gh` (requires `gh auth login`), ensure fetch succeeded, run `/pull-all` so local `main` matches remote.

## Report

One line per repo, with its branches indented beneath, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md). Do not paste the raw script output.

```text
ml-data      OK              was on main
  improve-isolated-run-logic   WOULD DELETE (ancestry)
ml-meta      REPORT ONLY     dirty working tree
  add-orchestration-support    WOULD DELETE (squash)

7 repos, 7 branches would be deleted, 0 kept
Next: bash scripts/cleanup-merged.sh --delete (after confirming)
```

Always state whether this was a report or an actual delete, and never imply a branch was removed in report mode.

## Notes

- Protected branches: `main`, `master`, `prod`, `develop`, `release`.
- Remote branches are not deleted here.
- Local deletes are recoverable from the reflog.
