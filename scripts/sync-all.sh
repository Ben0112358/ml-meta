#!/bin/bash
set -euo pipefail

# Convenience one-shot: atomic checkout-main-all then pull-all.
# Prefer the split scripts (or /checkout-main-all then /pull-all) for post-merge work.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/checkout-main-all.sh" "$@"
"$SCRIPT_DIR/pull-all.sh" "$@"
