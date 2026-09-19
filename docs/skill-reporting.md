# Skill reporting standard

Applies to every skill that **executes** something (scripts, `git add`, `git restore --staged`, scaffolding).

Skills that only emit copyable text (`/commit-all-command`, `/push-all-command`, `/pr-desc-all`) are exempt: their output **is** the deliverable.

## Rule

Report **one short line per repository**, then **one summary line**. Do not paste raw script output.

```text
<repo>   <OUTCOME>   <short detail>
```

- **Outcome** is a single uppercase token: `OK`, `FAIL`, `SKIPPED`, `BLOCKED`, `REFUSED`, `NO CHANGE`.
- **Detail** is at most a short phrase: what happened or why not (`3 flake8 issues`, `dirty working tree`, `already on main`).
- Repos that were untouched may be collapsed into one line: `unchanged: ml-infra, ml-pipeline`.
- End with counts and, when relevant, the single most useful next command or skill.

## Example

```text
ml-data       OK        2 tests passed
ml-training   FAIL      flake8: 3 issues
ml-infra      SKIPPED   terraform not installed
unchanged: ml-serving, ml-ui, ml-pipeline, ml-meta

1 ok, 1 failed, 1 skipped. Next: bash scripts/lint-all.sh --fix ml-training
```

## Notes

- Prefer a table when there are more than two columns of useful information.
- Surface full script output only when the user asks, or when a failure cannot be explained in one line.
- Never claim success for a repo the script reported as skipped or blocked.
