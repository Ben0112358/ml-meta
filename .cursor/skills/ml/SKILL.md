---
name: ml
description: Run ml-meta scripts/ml.sh to print a repo path, show git status, open a gnome-terminal, or open pipeline repos in Cursor. Use when the user asks for ml, ml status, ml term, ml open, ml path, or ml task.
disable-model-invocation: true
---

# ml

Wraps `scripts/ml.sh`. `ml cd` and the `cd` after `ml open` only work in an interactive shell that has sourced `scripts/shell/ml.bash`. Do not edit `~/.bashrc`. Running `bash scripts/ml.sh open` launches Cursor and does not change directory.

## Instructions

1. From `$ML_HOMELAB_ROOT/ml-meta`, run the command the user asked for:
   ```bash
   bash scripts/ml.sh status
   bash scripts/ml.sh path ml-data
   bash scripts/ml.sh --dry-run term ml-data
   bash scripts/ml.sh term ml-data
   bash scripts/ml.sh --dry-run open
   bash scripts/ml.sh open
   bash scripts/ml.sh task
   bash scripts/ml.sh task set --branch <name> --project <project> ml-data ml-training
   ```
2. `term` opens a gnome-terminal tab. `open` launches a new classic Cursor editor window (`cursor -n --classic`). Run those without `--dry-run` only when the user asked to open a terminal or a Cursor window.
3. Do not modify repositories. `task set` writes `~/.config/ml-meta/task` only.
4. This does not invoke other Cursor skills. Status output comes from `scripts/status-all.sh`.

## Report

One short line per repository, then a summary line, when more than one repo is involved. See [skill-reporting.md](../../docs/skill-reporting.md). Do not paste raw script output. For `term`, the script's single report line is the result. For `open`, report the folder list and whether Cursor was launched. For `status`, use the `/status-all` report shape.

```text
ml-data    OK       term config, ~/venvs/ml_data_3_13
ml-infra   OK       term none

open ml-meta ml-infra ml-data ml-training ml-serving ml-ui ml-pipeline
```
