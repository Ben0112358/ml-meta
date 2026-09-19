#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

FIX=0
META_REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	--fix)
		FIX=1
		shift
		;;
	--dry-run)
		DRY_RUN=1
		shift
		;;
	-*)
		echo "Unknown option: $1" >&2
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

ok=0
failed=0
skipped=0
needs_init=0

lint_python() {
	local dir="$1"
	if ! tool_available black || ! tool_available flake8; then
		echo "SKIPPED (black or flake8 not found)"
		return 2
	fi
	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "OK (dry-run)"
		return 0
	fi
	if [[ "$FIX" -eq 1 ]]; then
		black "$dir" || return 1
	fi
	if ! black --check "$dir" >/dev/null 2>&1; then
		echo "FAIL (black)"
		return 1
	fi
	if ! flake8 "$dir" >/dev/null 2>&1; then
		echo "FAIL (flake8)"
		return 1
	fi
	echo "OK"
	return 0
}

lint_bash() {
	local dir="$1"
	if ! tool_available shfmt; then
		echo "SKIPPED (shfmt not found)"
		return 2
	fi
	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "OK (dry-run)"
		return 0
	fi
	if [[ "$FIX" -eq 1 ]]; then
		shfmt -w "$dir" || return 1
	fi
	if shfmt -d "$dir" >/dev/null 2>&1; then
		echo "OK"
		return 0
	fi
	echo "FAIL (shfmt)"
	return 1
}

terraform_validate_needs_init() {
	local err="$1"
	grep -qE 'Module not installed|Could not load plugin|Initialization required|please run "terraform init"|Run "terraform init"' <<<"$err"
}

lint_terraform() {
	local dir="$1"
	local validate_err
	if ! tool_available terraform; then
		echo "SKIPPED (terraform not found)"
		return 2
	fi
	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "OK (dry-run)"
		return 0
	fi
	if [[ "$FIX" -eq 1 ]]; then
		terraform -chdir="$dir" fmt -recursive || return 1
	fi
	if ! terraform -chdir="$dir" fmt -check -recursive >/dev/null 2>&1; then
		echo "FAIL (terraform fmt)"
		return 1
	fi
	if [[ ! -d "${dir}/.terraform" ]]; then
		echo "NEEDS-INIT (run: terraform -chdir=\"${dir}\" init)"
		return 3
	fi
	validate_err="$(terraform -chdir="$dir" validate 2>&1)"
	local validate_rc=$?
	if [[ "$validate_rc" -eq 0 ]]; then
		echo "OK"
		return 0
	fi
	if terraform_validate_needs_init "$validate_err"; then
		echo "NEEDS-INIT (run: terraform -chdir=\"${dir}\" init)"
		return 3
	fi
	echo "FAIL (terraform validate)"
	return 1
}

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
	python) lint_python "$dir" ;;
	bash | docs) lint_bash "$dir" ;;
	terraform) lint_terraform "$dir" ;;
	*)
		echo "UNKNOWN KIND"
		rc=1
		;;
	esac
	rc=$?
	set -e
	case "$rc" in
	0) ok=$((ok + 1)) ;;
	2) skipped=$((skipped + 1)) ;;
	3) needs_init=$((needs_init + 1)) ;;
	*) failed=$((failed + 1)) ;;
	esac
done

echo ""
echo "${ok} ok, ${failed} failed, ${skipped} skipped, ${needs_init} needs-init"
if [[ "$failed" -gt 0 || "$skipped" -gt 0 ]]; then
	exit 1
fi
exit 0
