---
name: commit-all-command
description: Generate one copyable shell string of git commit commands with proposed messages per pipeline repository, based on what is already staged. Use when the user asks for commit-all-command, wants commit messages across repos, or runs /commit-all-command. Never runs git commit and never stages files.
disable-model-invocation: true
---

# commit-all-command

Commit messages only, for changes that are **already staged**. Do **not** run `git commit`, `git add`, or `git push`. Staging is `/add-all`; selective unstaging is `/unstage-selected`.

## Instructions

### 1. Inspect staged changes (read-only)

Walk repos under `$ML_HOMELAB_ROOT` in this order: `ml-infra`, `ml-data`, `ml-training`, `ml-serving`, `ml-ui`, `ml-pipeline`, `ml-meta`.

Per repo:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" diff --cached
git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current
```

If a repo has nothing staged, skip it in the output chain and note that it needs `/add-all` first.

### 2. Write one message per repo

- Maximum one short sentence, roughly 74 characters.
- No quotation marks inside the message text.
- Describe the change in that repo only, not the wider cross-repo feature.
- Base the message strictly on staged content, not on unstaged edits.

### 3. Output one copyable command string

Emit **exactly one** fenced `bash` block containing **all** commits for repos that have staged changes.

- Chain with `&&` so the shell stops on the first failed commit (hooks, empty index, wrong branch).
- Use `git -C "$ML_HOMELAB_ROOT/<repo>" commit -m "..."` so the user does not need multiple `cd` lines.
- Order commits in pipeline merge order (same repo walk as step 1).
- Line-break with `\` at end of each line except the last, for readability; still one pasteable script.

Example shape (messages are illustrative):

```bash
git -C "$ML_HOMELAB_ROOT/ml-infra" commit -m "Align terraform_logs path with logs/infra" && \
git -C "$ML_HOMELAB_ROOT/ml-data" commit -m "Add flake8 config and config smoke tests" && \
git -C "$ML_HOMELAB_ROOT/ml-training" commit -m "Fix MODEL_DIR validation and add smoke tests"
```

Do **not** split commits into multiple fenced blocks.

### 4. Report unstaged work

After the single command block, list repos that have unstaged changes or nothing staged, so the user can run `/add-all` again or `/unstage-selected` before committing.

### 5. Cross-repo note

When several repos appear in the chain, state merge order from [docs/architecture.md](../../docs/architecture.md) (same as commit order in the string), then point to `/push-all-command` and `/pr-desc-all`.

## Output rules

- One `bash` fence for all commit commands; prose (unstaged list, merge note) outside the fence.
- No emojis.
