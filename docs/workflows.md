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
| Check out `main` everywhere (atomic) | skill `/checkout-main-all` — no unpushed commits; no tracked edits; see readiness below |
| Refresh python lockfiles | skill `/poetry-lock-and-sync-all` — `ml-data` … `ml-ui` only |
| Pull `main` everywhere (atomic) | skill `/pull-all` — all repos must already be on `main` |
| One-shot sync | `bash scripts/sync-all.sh` (= checkout-main-all then pull-all) |
| Same branch name in N repos | skill `/branch-all` or `bash scripts/branch-all.sh <name> [repos...]` |
| Lint all toolchains | `bash scripts/lint-all.sh` (`--fix` to format) |
| Test python stages | `bash scripts/test-all.sh` |
| Lint + test | skill `/check-all` |
| Stage across repos | skill `/add-all` (stages explicit paths, scans, reports what was left out) |
| Unstage selected staged paths | skill `/unstage-selected` (by description; `git restore --staged` only) |
| Check what is staged | `bash scripts/scan-staged.sh` |
| Copyable `git commit` per repo | skill `/commit-all-command` (messages for already-staged changes) |
| Copyable `git push` per repo | skill `/push-all-command` (merge order; does not run push) |
| Copyable PR markdown per repo | skill `/pr-desc-all` (does not run `gh pr create`) |
| After PRs merge: main + branch cleanup | `bash scripts/cleanup-merged.sh` (report), then `--delete`; or skill `/cleanup-merged` |

Irreversible steps stay under your control: `git commit`, `git push`, and opening PRs are emitted as copyable commands, never run for you. Staging is run directly because `git restore --staged` undoes it.

Skills that execute something report one short line per repository plus a summary line, rather than pasting raw script output. See [skill-reporting.md](skill-reporting.md).

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

## Git readiness (checkout-main-all / pull-all)

Scripts use `scripts/lib/common.sh` (`repo_ready_reason`). A repo **blocks** when:

- it has **no** local `main` branch;
- it has **unpushed commits** on the current branch;
- it has **tracked** changes (staged or unstaged vs `HEAD`);
- it has **untracked** files that are not on the allowlist below.

**Allowed untracked files** (safe to ignore; do not belong on GitHub). Basename must match; defined in `untracked_ok_basename()` in `common.sh`:

| Basename | Why it is disregarded |
|----------|------------------------|
| `pip-audit.json` | Local or CI `pip-audit -o` output from the security workflow; scan report only |
| `trivy-results.sarif` | Filesystem Trivy SARIF when generated locally; not part of the repo |
| `opengrep.sarif` | Opengrep SARIF when generated locally; not part of the repo |
| `install-opengrep.sh` | One-off installer script from opengrep setup; not project source |

Anything else untracked (new `.py`, `.toml`, `.env`, etc.) still blocks until you commit, delete, or add to `.gitignore` locally. Prefer committing real work; use `.gitignore` for recurring local junk when the allowlist is not enough.

## Post-merge (PRs merged, may still be on feature branch)

Typical sequence:

```text
/status-all  →  /checkout-main-all  →  /pull-all  →  /cleanup-merged
```

1. **checkout-main-all** — If every repo passes [git readiness](#git-readiness-checkout-main-all--pull-all), check out `main` in all of them. If any repo fails the gate, nothing is checked out.
2. **pull-all** — If every repo is on `main` and passes the same readiness gate, fetch and `pull --ff-only` everywhere. If any repo is not on `main`, nothing is pulled (run checkout-main-all first).
3. **cleanup-merged** — Report which local branches are already on `origin/main` (see below). Use `--delete` only when working trees are clean.

`sync-all.sh` runs checkout-main-all then pull-all in one command. Prefer the split steps when you want to inspect state between them.

## Post-merge branch cleanup

`scripts/cleanup-merged.sh` fetches and classifies local branches against **`origin/main`** (so squash-merged work is visible even while you are still on a feature branch or before local `main` is updated).

Because PRs are always squash merged, `git branch --merged` is unreliable. The script compares patch ids via a synthetic commit. Signals:

- `ancestry` — branch tip is already an ancestor of the merge target
- `squash` — branch tree matches a squash commit on the merge target
- `pr-merged` — GitHub reports a merged PR (only with `--gh`)

Safety rules:

- Report mode (default): classifies branches even in **dirty** repos (`dirty — report only`); no checkout or delete.
- `--delete`: refuses dirty repos; on clean repos checks out `main`, fast-forwards toward `origin/main`, then deletes merged branches.
- Protected: `main`, `master`, `prod`, `develop`, `release`.
- Local branches only.

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
