#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

parse_global_flags "$@" || exit 1
resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"

ok=0
failed=0
refused=0

for repo in "${META_TARGET_REPOS[@]}"; do
	print_repo_header "$repo" "sync"
	if ! repo_exists "$repo"; then
		echo "MISSING"
		failed=$((failed + 1))
		continue
	fi
	dir="$(repo_path "$repo")"
	if git_is_dirty "$dir"; then
		echo "REFUSED (dirty working tree)"
		refused=$((refused + 1))
		continue
	fi
	if git_has_unpushed_commits "$dir"; then
		echo "REFUSED (unpushed commits)"
		refused=$((refused + 1))
		continue
	fi
	if ! run_or_dry_run "git fetch in ${repo}" git -C "$dir" fetch --prune; then
		echo "FAIL (fetch)"
		failed=$((failed + 1))
		continue
	fi
	if ! run_or_dry_run "git checkout main in ${repo}" git -C "$dir" checkout main; then
		echo "FAIL (checkout main)"
		failed=$((failed + 1))
		continue
	fi
	if ! run_or_dry_run "git pull in ${repo}" git -C "$dir" pull --ff-only; then
		echo "FAIL (pull)"
		failed=$((failed + 1))
		continue
	fi
	echo "OK"
	ok=$((ok + 1))
done

echo ""
echo "${ok} ok, ${failed} failed, ${refused} refused"
if [[ "$failed" -gt 0 || "$refused" -gt 0 ]]; then
	exit 1
fi
exit 0
