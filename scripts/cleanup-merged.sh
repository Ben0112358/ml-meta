#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

DELETE=0
USE_GH=0
META_REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	--delete)
		DELETE=1
		shift
		;;
	--gh)
		USE_GH=1
		shift
		;;
	--dry-run)
		DRY_RUN=1
		shift
		;;
	-*)
		echo "Unknown option: $1" >&2
		echo "Usage: $0 [--delete] [--gh] [--dry-run] [repo...]" >&2
		exit 1
		;;
	*)
		META_REMAINING_ARGS+=("$1")
		shift
		;;
	esac
done

resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"
if [[ "$DELETE" -eq 0 ]]; then
	log "INFO" "Report mode. Re-run with --delete to remove merged branches."
fi

gh_reports_merged() {
	local dir="$1"
	local branch="$2"
	tool_available gh || return 1
	gh auth status >/dev/null 2>&1 || return 1
	local count
	count="$(cd "$dir" && gh pr list --head "$branch" --state merged --json number --jq 'length' 2>/dev/null)"
	[[ "${count:-0}" -gt 0 ]]
}

# Echoes the signal that proves the branch is merged into target_ref, or nothing.
merge_signal() {
	local dir="$1"
	local branch="$2"
	local target_ref="$3"

	if git -C "$dir" merge-base --is-ancestor "$branch" "$target_ref" 2>/dev/null; then
		echo "ancestry"
		return 0
	fi

	local base tree synthetic cherry
	base="$(git -C "$dir" merge-base "$target_ref" "$branch" 2>/dev/null)" || return 1
	tree="$(git -C "$dir" rev-parse "${branch}^{tree}" 2>/dev/null)" || return 1
	synthetic="$(git -C "$dir" commit-tree "$tree" -p "$base" -m _ 2>/dev/null)" || return 1
	cherry="$(git -C "$dir" cherry "$target_ref" "$synthetic" 2>/dev/null)" || return 1
	if [[ "$cherry" == -* ]]; then
		echo "squash"
		return 0
	fi

	if [[ "$USE_GH" -eq 1 ]] && gh_reports_merged "$dir" "$branch"; then
		echo "pr-merged"
		return 0
	fi

	return 1
}

is_protected_branch() {
	case "$1" in
	main | master | prod | develop | release) return 0 ;;
	*) return 1 ;;
	esac
}

fast_forward_main() {
	local dir="$1"
	local repo="$2"
	if git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/${MAIN_BRANCH}"; then
		if run_or_dry_run "git merge --ff-only origin/${MAIN_BRANCH} in ${repo}" \
			git -C "$dir" merge --ff-only "origin/${MAIN_BRANCH}"; then
			return 0
		fi
		log "WARNING" "${repo}: could not fast-forward ${MAIN_BRANCH} to origin/${MAIN_BRANCH}"
		return 1
	fi
	if git_has_upstream "$dir"; then
		if run_or_dry_run "git pull --ff-only in ${repo}" git -C "$dir" pull --ff-only --quiet; then
			return 0
		fi
		log "WARNING" "${repo}: pull --ff-only failed"
		return 1
	fi
	log "WARNING" "${repo}: no origin/${MAIN_BRANCH} or upstream; local ${MAIN_BRANCH} unchanged"
	return 1
}

classify_and_maybe_delete_branches() {
	local repo="$1"
	local dir="$2"
	local target_ref="$3"
	local allow_delete="$4"

	while IFS= read -r branch; do
		[[ -z "$branch" ]] && continue
		is_protected_branch "$branch" && continue

		signal="$(merge_signal "$dir" "$branch" "$target_ref")"
		if [[ -z "$signal" ]]; then
			printf "               %-38s KEEP (not merged)\n" "$branch"
			branches_kept=$((branches_kept + 1))
			continue
		fi

		if [[ "$allow_delete" -eq 0 || "$DRY_RUN" -eq 1 ]]; then
			printf "               %-38s WOULD DELETE (%s)\n" "$branch" "$signal"
			branches_pending=$((branches_pending + 1))
			continue
		fi

		if [[ "$signal" == "ancestry" ]]; then
			delete_flag="-d"
		else
			delete_flag="-D"
		fi

		if git -C "$dir" branch "$delete_flag" "$branch" >/dev/null 2>&1; then
			printf "               %-38s DELETED (%s)\n" "$branch" "$signal"
			branches_removed=$((branches_removed + 1))
		else
			printf "               %-38s FAIL (delete)\n" "$branch"
			repos_failed=$((repos_failed + 1))
		fi
	done < <(git -C "$dir" for-each-ref --format='%(refname:short)' refs/heads/)
}

repos_ok=0
repos_failed=0
repos_refused=0
branches_removed=0
branches_pending=0
branches_kept=0

for repo in "${META_TARGET_REPOS[@]}"; do
	print_repo_header "$repo" "cleanup"
	if ! repo_exists "$repo"; then
		echo "MISSING"
		repos_failed=$((repos_failed + 1))
		continue
	fi
	dir="$(repo_path "$repo")"

	if ! git -C "$dir" show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
		echo "REFUSED (no ${MAIN_BRANCH} branch)"
		repos_refused=$((repos_refused + 1))
		continue
	fi

	was_on="$(git -C "$dir" branch --show-current 2>/dev/null || echo "?")"
	echo "was on: ${was_on}"

	if ! run_or_dry_run "git fetch --prune in ${repo}" git -C "$dir" fetch --prune --quiet; then
		echo "FAIL (fetch)"
		repos_failed=$((repos_failed + 1))
		continue
	fi

	target_ref="$(merge_target_ref "$dir")"
	dirty=0
	if git_is_dirty "$dir"; then
		dirty=1
	fi

	allow_delete=0
	if [[ "$DELETE" -eq 1 ]]; then
		if [[ "$dirty" -eq 1 ]]; then
			echo "REFUSED delete (dirty working tree)"
			repos_refused=$((repos_refused + 1))
		else
			current="$(git -C "$dir" branch --show-current 2>/dev/null || true)"
			if [[ "$current" != "$MAIN_BRANCH" ]]; then
				if ! run_or_dry_run "git checkout ${MAIN_BRANCH} in ${repo}" \
					git -C "$dir" checkout --quiet "$MAIN_BRANCH"; then
					echo "FAIL (checkout ${MAIN_BRANCH})"
					repos_failed=$((repos_failed + 1))
					continue
				fi
			fi
			fast_forward_main "$dir" "$repo" || true
			allow_delete=1
			echo "on ${MAIN_BRANCH}, classify vs ${target_ref}"
		fi
	else
		if [[ "$dirty" -eq 1 ]]; then
			echo "dirty — report only (classify vs ${target_ref})"
		else
			echo "report only (classify vs ${target_ref})"
		fi
	fi

	repos_ok=$((repos_ok + 1))
	classify_and_maybe_delete_branches "$repo" "$dir" "$target_ref" "$allow_delete"
done

echo ""
echo "repos: ${repos_ok} ok, ${repos_failed} failed, ${repos_refused} refused"
if [[ "$DELETE" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
	echo "branches: ${branches_removed} deleted, ${branches_kept} kept"
else
	echo "branches: ${branches_pending} would be deleted, ${branches_kept} kept"
fi

if [[ "$repos_failed" -gt 0 ]]; then
	exit 1
fi
if [[ "$DELETE" -eq 1 && "$repos_refused" -gt 0 ]]; then
	exit 1
fi
exit 0
