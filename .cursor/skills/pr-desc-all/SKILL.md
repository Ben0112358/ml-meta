---
name: pr-desc-all
description: Generate copyable per-repo pull request description markdown for pipeline repositories, based on origin/main..HEAD. Use when the user asks for pr descriptions across repos, pr-desc-all, or runs /pr-desc-all. Never runs gh pr create or opens PRs.
disable-model-invocation: true
---

# pr-desc-all

PR description markdown only. Do **not** run `git push`, `gh pr create`, or open pull requests. Pushes are `/push-all-command`.

## Instructions

### Scope

One description per repository that has commits ahead of `origin/main` (or that the user scoped). Process in merge order:

`ml-infra` → `ml-data` → `ml-training` → `ml-serving` → `ml-ui` → `ml-pipeline` → `ml-meta`

### Gather context (read-only)

Per repo with work:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current
git -C "$ML_HOMELAB_ROOT/<repo>" log origin/main..HEAD --oneline
git -C "$ML_HOMELAB_ROOT/<repo>" diff origin/main...HEAD
```

Optional: `git fetch origin` before diff. Read changed files when the diff alone is unclear.

### Output

For each repo, one separate fenced **markdown** block (raw markdown for paste into GitHub), using:

```markdown
# [Proposed Title]

## Summary
- ...

## Key Changes
- **...**: ...

## Test Plan
- ...

## Depends on
- Other repos or PRs that should merge first; omit section if none
```

Cross-repo features: state merge order and dependencies (training before serving when model loading changes).

Skip repos with no commits to describe; say so in a short line after the blocks.

### Output rules

- No emojis.
- Do not call `gh pr create`.
