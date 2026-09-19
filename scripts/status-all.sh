#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

parse_global_flags "$@" || exit 1
resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"

for repo in "${META_TARGET_REPOS[@]}"; do
	kind="$(repo_kind "$repo")"
	print_repo_header "$repo" "$kind"
	if ! repo_exists "$repo"; then
		echo "MISSING (no .git at $(repo_path "$repo"))"
		continue
	fi
	dir="$(repo_path "$repo")"
	branch="$(git -C "$dir" branch --show-current 2>/dev/null || echo "?")"
	ab="$(git_ahead_behind "$dir")"
	staged="$(git -C "$dir" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
	unstaged="$(git -C "$dir" diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
	untracked="$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"
	if [[ "$ab" == "no-upstream" ]]; then
		echo "branch=${branch} upstream=none staged=${staged} unstaged=${unstaged} untracked=${untracked}"
	else
		read -r behind ahead <<<"$ab"
		echo "branch=${branch} ahead=${ahead} behind=${behind} staged=${staged} unstaged=${unstaged} untracked=${untracked}"
	fi
done

exit 0
