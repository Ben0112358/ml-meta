#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

BRANCH=""
META_REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		DRY_RUN=1
		shift
		;;
	-*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	*)
		if [[ -z "$BRANCH" ]]; then
			BRANCH="$1"
		else
			META_REMAINING_ARGS+=("$1")
		fi
		shift
		;;
	esac
done

if [[ -z "$BRANCH" ]]; then
	echo "Usage: $0 <branch-name> [--dry-run] [repo...]" >&2
	exit 1
fi

resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"
log "INFO" "Branch name: ${BRANCH}"

ok=0
failed=0
skipped=0

for repo in "${META_TARGET_REPOS[@]}"; do
	print_repo_header "$repo" "branch"
	if ! repo_exists "$repo"; then
		echo "MISSING"
		failed=$((failed + 1))
		continue
	fi
	dir="$(repo_path "$repo")"
	current="$(git -C "$dir" branch --show-current 2>/dev/null || true)"
	if [[ "$current" == "$BRANCH" ]]; then
		echo "OK (already on ${BRANCH})"
		ok=$((ok + 1))
		continue
	fi
	if git -C "$dir" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
		if run_or_dry_run "git checkout ${BRANCH} in ${repo}" git -C "$dir" checkout "$BRANCH"; then
			echo "OK (checked out existing)"
			ok=$((ok + 1))
		else
			echo "FAIL (checkout)"
			failed=$((failed + 1))
		fi
		continue
	fi
	if run_or_dry_run "git checkout -b ${BRANCH} in ${repo}" git -C "$dir" checkout -b "$BRANCH"; then
		echo "OK (created)"
		ok=$((ok + 1))
	else
		echo "FAIL (create branch)"
		failed=$((failed + 1))
	fi
done

finish_summary "$ok" "$failed" "$skipped"
exit $?
