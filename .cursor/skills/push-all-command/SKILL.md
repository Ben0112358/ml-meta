---
name: push-all-command
description: Generate one copyable shell string of git push commands in merge order for pipeline repositories that have commits to publish. Use when the user asks for push-all-command or runs /push-all-command. Never runs git push or gh pr create.
disable-model-invocation: true
---

# push-all-command

Push commands only. Do **not** run `git push`, `gh pr create`, or open pull requests. PR markdown is `/pr-desc-all`.

## Instructions

### Merge order

Push in this order (omit repos with nothing to push from the command string):

`ml-infra` → `ml-data` → `ml-training` → `ml-serving` → `ml-ui` → `ml-pipeline` → `ml-meta`

### Gather context (read-only)

For each repo:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current
git -C "$ML_HOMELAB_ROOT/<repo>" status --porcelain -b
git -C "$ML_HOMELAB_ROOT/<repo>" log origin/main..HEAD --oneline
```

Optional: `git fetch origin` per repo if needed to compare with remote.

Include a repo in the push chain only when `origin/main..HEAD` has commits (or the branch should be published and has no upstream yet).

Use the same branch name from `branch --show-current` for every repo in the chain unless the user scoped otherwise.

### Output one copyable command string

Emit **exactly one** fenced `bash` block containing **all** pushes for repos that need them.

- Chain with `&&` so the shell stops on the first failed push (auth, rejected, wrong branch).
- Use `git -C "$ML_HOMELAB_ROOT/<repo>" push -u origin <branch>` so the user does not need multiple `cd` lines.
- Order pushes in pipeline merge order (same as above).
- Line-break with `\` at end of each line except the last, for readability; still one pasteable script.
- Use `-u` on each push when upstream may be unset (typical for feature branches).

Example shape (branch name is illustrative):

```bash
git -C "$ML_HOMELAB_ROOT/ml-infra" push -u origin structural-improvements && \
git -C "$ML_HOMELAB_ROOT/ml-data" push -u origin structural-improvements && \
git -C "$ML_HOMELAB_ROOT/ml-training" push -u origin structural-improvements
```

Do **not** split pushes into multiple fenced blocks.

After the block, list repos **skipped** (no commits ahead of `origin/main`, already pushed, or nothing to publish).

Note merge-order dependencies briefly when relevant (for example training before serving when model loading changed), then point to `/pr-desc-all` for PR text.

## Output rules

- One `bash` fence for all push commands; prose (skipped repos, merge note) outside the fence.
- No emojis.
