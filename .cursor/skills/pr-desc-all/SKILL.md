---
name: pr-desc-all
description: Generate copyable PR title and description body per pipeline repository from origin/main..HEAD. Use for pr-desc-all or /pr-desc-all. Never runs git push, gh pr create, or opens PRs.
disable-model-invocation: true
---

# pr-desc-all

PR text only. Do **not** run `git push`, `gh pr create`, or open pull requests. Pushes are `/push-all-command`.

## Instructions

### Scope

One title + one description **body** per repository with commits ahead of `origin/main` (or repos the user scoped). Process in merge order:

`ml-infra` → `ml-data` → `ml-training` → `ml-serving` → `ml-ui` → `ml-pipeline` → `ml-meta`

### Gather context (read-only)

Per repo with work:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" branch --show-current
git -C "$ML_HOMELAB_ROOT/<repo>" log origin/main..HEAD --oneline
git -C "$ML_HOMELAB_ROOT/<repo>" diff origin/main...HEAD
```

Optional: `git fetch origin` before diff. Read changed files when the diff alone is unclear.

### Output format (per repo)

For **each** repo that needs a PR, emit in this order:

1. A visible **repo header** (plain text, not inside a fence):

   `### ml-data` (use the actual repo folder name)

2. **Title** — exactly **one** fenced block tagged `text` (or untagged plain fence) containing **only** the PR title line. No `#`, no quotes, no markdown heading. User pastes this into GitHub’s **Title** field.

   ```text
   fix: add working flake8 config and config smoke tests
   ```

3. **Description body** — exactly **one** fenced `markdown` block containing the rest of the PR description. **Do not** repeat the title as `# ...` at the top; the title is separate. Use:

   ```markdown
   ## Summary
   - ...

   ## Key Changes
   - **...**: ...

   ## Test Plan
   - [ ] ...

   ## Depends on
   - ... (omit entire section if none)
   ```

That is **two copyable blocks per repo** (title, then body). Repeat the trio (header + title fence + body fence) for the next repo.

Cross-repo features: put merge order and dependencies in **Depends on** (and optionally one bullet in Summary), not in the title.

Skip repos with no commits to describe; after all repos, one short line listing skipped names.

State overall PR merge order once in prose before the first repo when multiple repos are included.

### Output rules

- Repo header must make it obvious which GitHub repo the next two blocks belong to.
- No emojis.
- Do not call `gh pr create`.
- Do not combine title and body into a single fence.
