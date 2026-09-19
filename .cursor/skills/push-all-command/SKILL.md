---
name: push-all-command
description: Generate copyable git push origin commands in merge order for pipeline repositories that have commits to publish. Use when the user asks for push-all-command or runs /push-all-command. Never runs git push or gh pr create.
disable-model-invocation: true
---

# push-all-command

Push commands only. Do **not** run `git push`, `gh pr create`, or open pull requests. PR markdown is `/pr-desc-all`.

## Instructions

### Merge order

Push in this order (skip repos with nothing to push):

`ml-infra` → `ml-data` → `ml-training` → `ml-serving` → `ml-ui` → `ml-pipeline` → `ml-meta`

### Gather context (read-only)

For each repo:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current
git -C "$ML_HOMELAB_ROOT/<repo>" status --porcelain -b
git -C "$ML_HOMELAB_ROOT/<repo>" log origin/main..HEAD --oneline
```

Optional: `git fetch origin` per repo if needed to compare with remote.

Include a repo only when `origin/main..HEAD` has commits (or branch has no upstream but should be pushed).

### Output

One fenced shell block with copyable commands in merge order:

```bash
cd "$ML_HOMELAB_ROOT/ml-data"
git push -u origin <branch>
```

Use `-u` when the branch may not have an upstream yet.

After the block, list repos skipped (already up to date with origin, or no local commits).

Note merge-order dependencies briefly (for example merge ml-training before ml-serving when coupled), then point to `/pr-desc-all` for PR text.

### Output rules

- No emojis.
- Raw shell only in the push block.
