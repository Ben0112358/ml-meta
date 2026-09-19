# Workflows

## Single-repository loop

Typical flow inside one stage repo:

1. `git status`
2. `git checkout main` && `git pull`
3. `git branch <feature-branch>`
4. Implement and review changes
5. `black .` and `flake8 .` (python repos) or repo-specific lint
6. `poetry run pytest tests/` (python repos)
7. Stage explicit paths (avoid blind `git add .` on large trees)
8. `git commit -m "..."` 
9. `git push origin <feature-branch>`
10. Open a pull request manually

Use the global Cursor skills `generate-commit-message` and `pr-description-generator` when working in a single repo.

## Cross-repository loop (ml-meta)

Open the workspace at `$ML_HOMELAB_ROOT/ml-meta` so project skills under `.cursor/skills/` are available.

| Step | Tool |
|------|------|
| See state of all repos | `bash scripts/status-all.sh` or skill `/status-all` |
| Update main everywhere | `bash scripts/sync-all.sh` (refuses dirty or unpushed repos; use `--dry-run` first) |
| Same branch name in N repos | `bash scripts/branch-all.sh <name> [repos...]` |
| Lint all toolchains | `bash scripts/lint-all.sh` (`--fix` to format) |
| Test python stages | `bash scripts/test-all.sh` |
| Lint + test | skill `/check-all` |
| Stage across repos | skill `/add-all` (stages explicit paths, scans, reports what was left out) |
| Unstage selected staged paths | skill `/unstage-selected` (by description; `git restore --staged` only) |
| Check what is staged | `bash scripts/scan-staged.sh` |
| Copyable `git commit` per repo | skill `/commit-all-command` (messages for already-staged changes) |
| Copyable push + PR markdown | skill `/pr-all-command` (does not run `gh pr create`) |
| After PRs merge: main + branch cleanup | `bash scripts/cleanup-merged.sh` (report), then `--delete`; or skill `/cleanup-merged` |

Irreversible steps stay under your control: `git commit`, `git push`, and opening PRs are emitted as copyable commands, never run for you. Staging is run directly because `git restore --staged` undoes it.

## Staging safety

Everything staged is one commit away from being public on GitHub. `scripts/scan-staged.sh` inspects staged paths and diff content across repos and flags:

- credentials and key material (`.env`, `*.pem`, `*.key`, `.netrc`, `*.tfvars`)
- terraform state (`*.tfstate*`)
- tokens and keys in diff content (AWS, GitHub, Slack, generic `api_key=` style assignments)
- private key blocks
- data and model artifacts (`*.csv`, `*.parquet`, `*.pkl`, `*.joblib`)
- files over 1 MiB
- absolute home paths such as `/home/<name>/`, which leak the local username

It exits non-zero on any finding. Unstage with:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" restore --staged <path>
```

## Post-merge cleanup

`scripts/cleanup-merged.sh` fetches, checks out `main`, pulls, and removes local branches whose work already landed.

Because PRs are always squash merged, `git branch --merged` does not recognize those branches: the squash commit has different SHAs than the branch commits. The script therefore rebuilds each branch as a single synthetic commit and compares patch ids against `main`, which detects squash merges reliably. Detection signals reported per branch:

- `ancestry` — branch tip is already an ancestor of `main`
- `squash` — branch content matches a squash commit on `main`
- `pr-merged` — GitHub reports a merged PR (only with `--gh`)

Safety rules:

- Report-only by default; deletion requires `--delete`.
- Repos with uncommitted changes are refused.
- `main`, `master`, `prod`, `develop`, and `release` are never deleted.
- Local branches only. Remote branches are left to GitHub's delete-on-merge setting.

```bash
bash scripts/cleanup-merged.sh                 # report
bash scripts/cleanup-merged.sh --delete        # act
bash scripts/cleanup-merged.sh --delete ml-data ml-training
bash scripts/cleanup-merged.sh --gh            # ask GitHub when local checks say unmerged
```

## Running the full pipeline locally

From `$ML_HOMELAB_ROOT/ml-pipeline`:

```bash
export ML_HOMELAB_ROOT=...   # parent of all repos
bash execute.sh <project_name> dev
```

Use **dev** while iterating on unmerged branches across repos. **prod** only sees published `main` on each remote.

## Adding a new project

Follow [new-project.md](new-project.md) or skill `/new-project` to scaffold from `dummy_project`.
