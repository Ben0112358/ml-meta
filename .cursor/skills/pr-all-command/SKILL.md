---
name: pr-all-command
description: Generate copyable git push commands in merge order and per-repo PR description markdown for pipeline repositories. Use when the user asks for pr-all-command or runs /pr-all-command. Never runs gh pr create or opens PRs.
disable-model-invocation: true
---

# pr-all-command

## Instructions

Generate text for the user to copy. Do **not** run `git push`, `gh pr create`, or open pull requests.

### Merge order

Use this order for pushes and PR notes:

`ml-infra` → `ml-data` → `ml-training` → `ml-serving` → `ml-ui` → `ml-pipeline` → `ml-meta`

Skip repos with no commits to push.

### Gather context (read-only)

For each repo with work:

- `git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current`
- `git -C ... fetch origin` (optional, read-only network)
- `git -C ... log origin/main..HEAD --oneline`
- `git -C ... diff origin/main...HEAD`

### Push commands

One fenced block listing copyable pushes in merge order:

```bash
cd "$ML_HOMELAB_ROOT/ml-data"
git push origin <branch>
```

### PR descriptions

For each repo that needs a PR, output one separate fenced markdown block (raw markdown for copy-paste), using:

```markdown
# [Proposed Title]

## Summary
- ...

## Key Changes
- **...**: ...

## Test Plan
- ...

## Depends on
- Other repos or PRs if applicable; otherwise omit section
```

Cross-repo features: state which other repo PRs should merge first (for example training before serving).

### Output rules

- No emojis.
- Do not call `gh pr create`.
