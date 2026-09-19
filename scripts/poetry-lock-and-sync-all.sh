#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PYTHON_REPOS=(ml-data ml-training ml-serving ml-ui)

parse_global_flags "$@" || exit 1

if [[ ${#META_REMAINING_ARGS[@]} -eq 0 ]]; then
	META_TARGET_REPOS=("${PYTHON_REPOS[@]}")
else
	resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1
fi

export POETRY_KEYRING_ENABLED="${POETRY_KEYRING_ENABLED:-false}"

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"
log "INFO" "poetry lock + poetry sync in python stage repos"

ok=0
failed=0
skipped=0

for repo in "${META_TARGET_REPOS[@]}"; do
	kind="$(repo_kind "$repo")"
	print_repo_header "$repo" "$kind"
	if [[ "$kind" != python ]]; then
		echo "SKIPPED (not a python repo)"
		skipped=$((skipped + 1))
		continue
	fi
	if ! repo_exists "$repo"; then
		echo "MISSING"
		failed=$((failed + 1))
		continue
	fi
	if ! tool_available poetry; then
		echo "SKIPPED (poetry not found)"
		skipped=$((skipped + 1))
		continue
	fi
	dir="$(repo_path "$repo")"
	set +e
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "INFO" "[dry-run] poetry lock in ${dir}"
		log "INFO" "[dry-run] poetry sync --no-interaction in ${dir}"
		echo "OK (dry-run)"
		rc=0
	else
		if ! (cd "$dir" && poetry lock --no-interaction); then
			echo "FAIL (poetry lock)"
			rc=1
		elif ! (cd "$dir" && poetry sync --no-interaction); then
			echo "FAIL (poetry sync)"
			rc=1
		else
			echo "OK"
			rc=0
		fi
	fi
	set -e
	case "$rc" in
	0) ok=$((ok + 1)) ;;
	*) failed=$((failed + 1)) ;;
	esac
done

finish_summary "$ok" "$failed" "$skipped"
exit $?
