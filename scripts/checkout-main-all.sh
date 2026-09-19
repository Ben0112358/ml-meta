#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

parse_global_flags "$@" || exit 1
resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"
log "INFO" "All-or-nothing checkout of ${MAIN_BRANCH}"

blockers=()
for repo in "${META_TARGET_REPOS[@]}"; do
	if ! repo_exists "$repo"; then
		blockers+=("${repo}: missing checkout")
		continue
	fi
	dir="$(repo_path "$repo")"
	reason="$(repo_ready_reason "$dir")"
	if [[ -n "$reason" ]]; then
		blockers+=("${repo}: ${reason}")
	fi
done

if [[ "${#blockers[@]}" -gt 0 ]]; then
	echo "BLOCKED (no checkouts performed):"
	for line in "${blockers[@]}"; do
		echo "  ${line}"
	done
	exit 1
fi

ok=0
failed=0
for repo in "${META_TARGET_REPOS[@]}"; do
	dir="$(repo_path "$repo")"
	print_repo_header "$repo" "checkout"
	current="$(git -C "$dir" branch --show-current 2>/dev/null || true)"
	if [[ "$current" == "$MAIN_BRANCH" ]]; then
		echo "OK (already on ${MAIN_BRANCH})"
		ok=$((ok + 1))
		continue
	fi
	if run_or_dry_run "git checkout ${MAIN_BRANCH} in ${repo}" \
		git -C "$dir" checkout --quiet "$MAIN_BRANCH"; then
		echo "OK"
		ok=$((ok + 1))
	else
		echo "FAIL (checkout)"
		failed=$((failed + 1))
	fi
done

echo ""
echo "${ok} ok, ${failed} failed"
if [[ "$failed" -gt 0 ]]; then
	exit 1
fi
exit 0
