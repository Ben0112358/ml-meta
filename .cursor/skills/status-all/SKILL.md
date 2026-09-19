---
name: status-all
description: Run ml-meta scripts/status-all.sh across pipeline repositories and summarize branch, ahead/behind, and working tree state. Use when the user asks for status-all, cross-repo git status, or runs /status-all.
disable-model-invocation: true
---

# status-all

## Instructions

1. From `$ML_HOMELAB_ROOT/ml-meta`, run:
   ```bash
   bash scripts/status-all.sh
   ```
2. If the user named specific repos, append them: `bash scripts/status-all.sh ml-data ml-training`.
3. Summarize which repos are dirty, ahead of upstream, or missing.
4. Do not modify any repository.
