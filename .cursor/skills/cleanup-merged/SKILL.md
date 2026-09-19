---
name: cleanup-merged
description: Check out main, pull, and remove local branches whose work is already on main across pipeline repositories, including squash-merged branches that git branch --merged cannot detect. Use after PRs are merged, when the user asks to clean up merged branches, or runs /cleanup-merged.
disable-model-invocation: true
---

# cleanup-merged

Wraps `scripts/cleanup-merged.sh`. The script decides what is merged; do not judge that yourself.

## Instructions

1. From `$ML_HOMELAB_ROOT/ml-meta`, always report first:
   ```bash
   bash scripts/cleanup-merged.sh
   ```
   This fetches, checks out `main`, pulls, and lists branches as `WOULD DELETE (<signal>)` or `KEEP (not merged)`. It deletes nothing.

2. Show the user the list and the detection signal for each branch:
   - `ancestry` — branch tip is already an ancestor of `main`
   - `squash` — branch content matches a squash commit on `main` (patch id)
   - `pr-merged` — GitHub reports a merged PR for the branch (only with `--gh`)

3. Delete only after the user confirms:
   ```bash
   bash scripts/cleanup-merged.sh --delete
   ```

4. Scope to specific repos by appending names: `bash scripts/cleanup-merged.sh --delete ml-data ml-training`.

5. If a branch is reported `KEEP` but the user believes its PR was merged, re-run with `--gh` to ask GitHub directly (requires a working `gh auth status`).

## Notes

- Repos with uncommitted changes are refused; report them and let the user resolve.
- `main`, `master`, `prod`, `develop`, and `release` are never deleted.
- Remote branches are not touched. GitHub deletes them on merge when the repo setting is enabled; otherwise give the user copyable `git push origin --delete <branch>` commands rather than running them.
- Deleted branches remain recoverable from the reflog.
