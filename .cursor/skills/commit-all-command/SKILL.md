---
name: commit-all-command
description: Generate copyable git commit commands with proposed messages per pipeline repository, based on what is already staged. Use when the user asks for commit-all-command, wants commit messages across repos, or runs /commit-all-command. Never runs git commit and never stages files.
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

If a repo has nothing staged, skip it and note that it needs `/add-all` first.

### 2. Write one message per repo

- Maximum one short sentence, roughly 74 characters.
- No quotation marks inside the message text.
- Describe the change in that repo only, not the wider cross-repo feature.
- Base the message strictly on staged content, not on unstaged edits.

### 3. Output one block per repo

```bash
cd "$ML_HOMELAB_ROOT/<repo>"
git commit -m "message text here"
```

Commands must be ready to paste and run.

### 4. Report unstaged work

After the blocks, list repos that have unstaged changes or nothing staged, so the user can decide whether to run `/add-all` again, or `/unstage-selected` to drop something from the index, before committing.

### 5. Cross-repo note

When several repos are being committed for one feature, state the merge order from [docs/architecture.md](../../docs/architecture.md), then point to `/push-all-command` and `/pr-desc-all`.

## Output rules

- Raw shell inside fenced blocks.
- No emojis.
