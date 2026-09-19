---
name: add-all
description: Stage task-relevant changes across pipeline repositories with explicit paths, run a safety scan on the result, and report what was staged, what was left out, and why. Use when the user asks to stage changes across repos or runs /add-all. Stages only; never commits or pushes.
disable-model-invocation: true
---

# add-all

Staging is reversible, so this skill runs `git add` directly. Committing and pushing are not reversible once public, so this skill never runs `git commit`, `git push`, or `gh pr create`.

Treat everything staged as content that will end up in a public GitHub repository.

## Instructions

### 1. Inspect (read-only)

Walk repos under `$ML_HOMELAB_ROOT` in this order, skipping ones with no changes: `ml-infra`, `ml-data`, `ml-training`, `ml-serving`, `ml-ui`, `ml-pipeline`, `ml-meta`.

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" status --porcelain -uall
git -C "$ML_HOMELAB_ROOT/<repo>" diff
```

Read every changed file you do not recognize. Do not stage a file whose contents you have not reviewed.

### 2. Decide what to stage

Stage only paths belonging to the current task.

Never use `git add .`, `git add -A`, or `git add -u`. Always pass explicit paths.

Leave out by default, and say so in the report:

- credentials and key material: `.env`, `*.pem`, `*.key`, `id_rsa`, `.netrc`, `*.tfvars`
- terraform state: `*.tfstate`, `*.tfstate.*`, `.terraform/`
- generated or local files: `.terraform_envs`, logs, caches, build output
- data and model artifacts: `*.csv`, `*.parquet`, `*.pkl`, `*.joblib`
- anything containing an absolute home path or a personal name
- edits unrelated to the current task

If one file mixes task changes with unrelated edits, do not stage it. Flag it and suggest `git add -p <path>`.

### 3. Stage

Per repo:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" add <explicit paths>
```

### 4. Scan what is now staged

Always run the safety scan afterwards:

```bash
cd "$ML_HOMELAB_ROOT/ml-meta"
bash scripts/scan-staged.sh
```

It flags staged paths and diff content that look like secrets, credentials, tokens, private keys, data or model artifacts, oversized files, and absolute home paths. Exit code is non-zero when it finds something.

If the scan reports a finding, unstage that path with `/unstage-selected` or directly:

```bash
git -C "$ML_HOMELAB_ROOT/<repo>" restore --staged <path>
```

Re-run the scan until it is clean or the user explicitly accepts a finding.

### 5. Report

Report three sections:

- **Staged** — per repo, each path with a one-line reason it belongs to this task.
- **Not staged** — every remaining changed path with the reason (unrelated edit, generated artifact, secret, data file, work in progress).
- **Scan result** — findings count, and what was unstaged in response.

Close by pointing the user to `/unstage-selected` to drop specific paths from the index, then `/commit-all-command` to commit.

## Output rules

- No emojis.
- Never commit or push, even if the staging looks complete.
