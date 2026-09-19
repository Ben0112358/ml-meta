#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

parse_global_flags "$@" || exit 1
resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"

ok=0
failed=0
skipped=0

for repo in "${META_TARGET_REPOS[@]}"; do
	kind="$(repo_kind "$repo")"
	print_repo_header "$repo" "$kind"
	if ! repo_exists "$repo"; then
		echo "MISSING"
		failed=$((failed + 1))
		continue
	fi
	dir="$(repo_path "$repo")"
	set +e
	case "$kind" in
	python)
		if ! tool_available poetry; then
			echo "SKIPPED (poetry not found)"
			rc=2
		elif [[ "$DRY_RUN" -eq 1 ]]; then
			log "INFO" "[dry-run] poetry run pytest in ${dir}"
			echo "OK (dry-run)"
			rc=0
		else
			if (cd "$dir" && poetry run pytest); then
				echo "OK"
				rc=0
			else
				echo "FAIL (pytest)"
				rc=1
			fi
		fi
		;;
	bash | docs | terraform)
		echo "NO TESTS"
		ok=$((ok + 1))
		continue
		;;
	*)
		echo "UNKNOWN KIND"
		rc=1
		;;
	esac
	set -e
	case "$rc" in
	0)
		if [[ "$kind" == python ]]; then ok=$((ok + 1)); fi
		;;
	2) skipped=$((skipped + 1)) ;;
	*) failed=$((failed + 1)) ;;
	esac
done

finish_summary "$ok" "$failed" "$skipped"
exit $?
