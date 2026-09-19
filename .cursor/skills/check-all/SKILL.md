---
name: check-all
description: Run lint-all.sh and test-all.sh from ml-meta across pipeline repositories and report pass, fail, and skipped per repo. Use when the user asks for check-all, lint and test everything, or runs /check-all.
disable-model-invocation: true
---

# check-all

## Instructions

1. From `$ML_HOMELAB_ROOT/ml-meta`, run lint then tests:
   ```bash
   bash scripts/lint-all.sh
   bash scripts/test-all.sh
   ```
2. If lint failed on formatting-only issues, tell the user they may run `bash scripts/lint-all.sh --fix` and re-run check-all.
3. Pass through repo filters if the user scoped the request.
4. Report the summary counts from each script. Do not auto-fix unless the user asks.
