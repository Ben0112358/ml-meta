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
4. Do not auto-fix unless the user asks.

## Report

One line per repo covering both lint and test, then a summary line. See [skill-reporting.md](../../docs/skill-reporting.md). Do not paste raw pytest or flake8 output unless a failure needs it.

```text
ml-data       OK          lint ok, 2 tests passed
ml-training   FAIL        flake8: 3 issues
ml-infra      NEEDS-INIT  terraform init required
unchanged: ml-pipeline, ml-meta

lint: 5 ok, 1 failed, 1 needs-init | tests: 4 ok
Next: bash scripts/lint-all.sh --fix ml-training
```

`NEEDS-INIT` is not a failure; say so explicitly.
