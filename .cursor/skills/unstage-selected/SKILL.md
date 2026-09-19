---
name: unstage-selected
description: Unstage only the staged paths the user describes across pipeline repositories, using git restore --staged. Use when the user wants to remove specific files from the index, undo part of a git add, or runs /unstage-selected. Never unstages everything unless the user explicitly asks; never discards working tree changes.
disable-model-invocation: true
---

# unstage-selected

Removes **selected** paths from the index across repos. Working tree contents are never touched, so no edits are lost.

This is not a bulk reset: only paths that match the user's description are unstaged.

## Hard safety rules

- Only ever run `git restore --staged <path>`.
- Never run `git restore <path>` without `--staged`, `git checkout -- <path>`, `git reset --hard`, or `git clean`. Those discard work and are not recoverable.
- Never delete files.
- If the user seems to want their edits discarded rather than unstaged, stop and confirm explicitly before doing anything.

## Instructions

### 1. List what is staged

Walk repos under `$ML_HOMELAB_ROOT`: `ml-infra`, `ml-data`, `ml-training`, `ml-serving`, `ml-ui`, `ml-pipeline`, `ml-meta`.

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" diff --cached --name-only
```

Skip repos with an empty result.

### 2. Interpret the request

The user describes what to unstage in their own words, for example "the csv files", "everything in ml-ui", "the docs changes", "the thing with my home path in it".

Map the description to concrete staged paths:

- Match by repo, directory, extension, filename, or content as appropriate.
- Inspect content with `git -C <repo> diff --cached -- <path>` when the description refers to what a change contains rather than where it lives.
- If the description matches nothing, say so and list what is actually staged.
- If the description is ambiguous, or would unstage noticeably more than the user likely meant, show the matched list and ask before acting.
- Only unstage **all** staged paths in **all** repos when the user explicitly says so (for example "unstage everything that is staged").

### 3. Unstage

Per repo, with explicit paths:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" restore --staged <paths>
```

If a repo has no commits yet, `git restore --staged` fails with "could not resolve HEAD". Use this instead, which also only affects the index:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" rm --cached -- <paths>
```

### 4. Verify and report

Re-check the index:

```bash
cd "$ML_HOMELAB_ROOT/ml-meta"
bash scripts/scan-staged.sh
```

Report one line per repo, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md).

```text
ml-data   UNSTAGED   2 paths (data.csv, src/tmp.py)
ml-ui     NO CHANGE  nothing matched
unchanged: ml-infra, ml-training, ml-serving, ml-pipeline, ml-meta

2 unstaged, 4 still staged. Working tree untouched; edits are intact.
```

List the exact paths unstaged, never globs. Always confirm the working tree was not modified. If the user wanted a clean index, remind them the changes can be re-staged with `/add-all`.

## Output rules

- No emojis.
- Report paths exactly, never globs, so the user can see what happened.
