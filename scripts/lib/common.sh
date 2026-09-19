#!/bin/bash
# shellcheck source=scripts/lib/common.sh
# Shared helpers for ml-meta cross-repo scripts.

_meta_common_loaded="${_meta_common_loaded:-}"
if [[ -n "$_meta_common_loaded" ]]; then
	return 0 2>/dev/null || exit 0
fi
_meta_common_loaded=1

REPOS=(ml-infra ml-data ml-training ml-serving ml-ui ml-pipeline ml-meta)
MERGE_ORDER=(ml-infra ml-data ml-training ml-serving ml-ui ml-pipeline)

# Parent of ml-meta checkout.
_meta_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_meta_meta_root="$(cd "${_meta_script_dir}/../.." && pwd)"
ML_HOMELAB_ROOT="${ML_HOMELAB_ROOT:-$(cd "${_meta_meta_root}/.." && pwd)}"

DRY_RUN=0

log() {
	local severity="$1"
	local msg="$2"
	case "$severity" in
	INFO | WARNING | ERROR) ;;
	*)
		echo "Invalid log level: $severity" >&2
		return 1
		;;
	esac
	echo "$(date -u +"%a %b %d %T UTC %Y") - ${severity}: ${msg}"
}

repo_kind() {
	case "$1" in
	ml-data | ml-training | ml-serving | ml-ui) echo python ;;
	ml-pipeline) echo bash ;;
	ml-infra) echo terraform ;;
	ml-meta) echo docs ;;
	*)
		echo "unknown"
		return 1
		;;
	esac
}

repo_path() {
	echo "${ML_HOMELAB_ROOT}/$1"
}

repo_exists() {
	[[ -d "$(repo_path "$1")/.git" ]]
}

is_known_repo() {
	local r
	for r in "${REPOS[@]}"; do
		[[ "$r" == "$1" ]] && return 0
	done
	return 1
}

# After calling, use "${META_REMAINING_ARGS[@]}" for repo names.
parse_global_flags() {
	META_REMAINING_ARGS=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--)
			shift
			META_REMAINING_ARGS=("$@")
			return 0
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			META_REMAINING_ARGS+=("$1")
			shift
			;;
		esac
	done
}

# Sets META_TARGET_REPOS from names in "$@" or all REPOS if none.
resolve_target_repos() {
	META_TARGET_REPOS=()
	if [[ $# -eq 0 ]]; then
		META_TARGET_REPOS=("${REPOS[@]}")
		return 0
	fi
	local name
	for name in "$@"; do
		if ! is_known_repo "$name"; then
			echo "Unknown repository: ${name}" >&2
			return 1
		fi
		META_TARGET_REPOS+=("$name")
	done
}

print_repo_header() {
	printf "%-14s %-10s " "$1" "$2"
}

finish_summary() {
	local ok=$1 failed=$2 skipped=$3
	echo ""
	echo "${ok} ok, ${failed} failed, ${skipped} skipped"
	if [[ "$failed" -gt 0 || "$skipped" -gt 0 ]]; then
		return 1
	fi
	return 0
}

run_or_dry_run() {
	local desc="$1"
	shift
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "INFO" "[dry-run] ${desc}"
		log "INFO" "[dry-run] $*"
		return 0
	fi
	"$@"
}

tool_available() {
	command -v "$1" >/dev/null 2>&1
}

git_has_upstream() {
	local repo_dir="$1"
	git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1
}

_git_left_right_counts() {
	local repo_dir="$1"
	local range="$2"
	git -C "$repo_dir" rev-list --left-right --count "$range" 2>/dev/null | tr '\t' ' '
}

git_ahead_behind() {
	local repo_dir="$1"
	if ! git_has_upstream "$repo_dir"; then
		echo "no-upstream"
		return 0
	fi
	local counts behind ahead
	counts="$(_git_left_right_counts "$repo_dir" '@{upstream}...HEAD' || echo "? ?")"
	read -r behind ahead <<<"$counts"
	echo "${behind} ${ahead}"
}

git_is_dirty() {
	local repo_dir="$1"
	[[ -n "$(git -C "$repo_dir" status --porcelain 2>/dev/null)" ]]
}

git_has_unpushed_commits() {
	local repo_dir="$1"
	if ! git_has_upstream "$repo_dir"; then
		local branch
		branch="$(git -C "$repo_dir" branch --show-current 2>/dev/null || true)"
		if [[ -n "$branch" ]] && git -C "$repo_dir" rev-parse "origin/${branch}" >/dev/null 2>&1; then
			local counts behind ahead
			counts="$(_git_left_right_counts "$repo_dir" "origin/${branch}...HEAD" || echo "0 0")"
			read -r behind ahead <<<"$counts"
			[[ "${ahead:-0}" -gt 0 ]]
			return
		fi
		# Local-only branch with commits not on any remote: treat as unpushed if ahead of main
		return 1
	fi
	local counts behind ahead
	counts="$(_git_left_right_counts "$repo_dir" '@{upstream}...HEAD' || echo "0 0")"
	read -r behind ahead <<<"$counts"
	[[ "${ahead:-0}" -gt 0 ]]
}
