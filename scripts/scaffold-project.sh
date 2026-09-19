#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PROJECT=""
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
		if [[ -z "$PROJECT" ]]; then
			PROJECT="$1"
		else
			echo "Unexpected argument: $1" >&2
			exit 1
		fi
		shift
		;;
	esac
done

if [[ -z "$PROJECT" ]]; then
	echo "Usage: $0 <project_name> [--dry-run]" >&2
	exit 1
fi

if [[ ! "$PROJECT" =~ ^[a-z][a-z0-9_]*$ ]]; then
	echo "Project name must be snake_case (lowercase letters, digits, underscores)." >&2
	exit 1
fi

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"
log "INFO" "Scaffolding project: ${PROJECT}"

scaffold_stage() {
	local repo="$1"
	local pkg="$2"
	local module_suffix="$3"

	local root="$(repo_path "$repo")"
	local src="${root}/src/${pkg}/dummy_project"
	local dest="${root}/src/${pkg}/${PROJECT}"

	if ! repo_exists "$repo"; then
		log "ERROR" "Missing repo ${repo} at ${root}"
		return 1
	fi
	if [[ -e "$dest" ]]; then
		log "ERROR" "Already exists: ${dest}"
		return 1
	fi

	log "INFO" "${repo}: copy dummy_project -> ${PROJECT}"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "INFO" "[dry-run] cp -r ${src} ${dest}"
		log "INFO" "[dry-run] sed dummy_project -> ${PROJECT} under ${dest}"
		log "INFO" "[dry-run] copy Dockerfile.dummy_project and docker-compose.dummy_project.yaml"
		return 0
	fi

	cp -r "$src" "$dest"
	find "$dest" -type f -name '*.py' -print0 | while IFS= read -r -d '' f; do
		sed -i "s/dummy_project/${PROJECT}/g" "$f"
	done

	cp "${root}/Dockerfile.dummy_project" "${root}/Dockerfile.${PROJECT}"
	cp "${root}/docker-compose.dummy_project.yaml" "${root}/docker-compose.${PROJECT}.yaml"
	sed -i "s/dummy_project/${PROJECT}/g" "${root}/Dockerfile.${PROJECT}"
	sed -i "s/dummy_project/${PROJECT}/g" "${root}/docker-compose.${PROJECT}.yaml"

	case "$repo" in
	ml-data)
		sed -i "s/ml_data\.dummy_project\.data/ml_data.${PROJECT}.data/" "${root}/Dockerfile.${PROJECT}"
		;;
	ml-training)
		sed -i "s/ml_training\.dummy_project\.training/ml_training.${PROJECT}.training/" "${root}/Dockerfile.${PROJECT}"
		;;
	ml-serving)
		sed -i "s/dummy_project\.serving/${PROJECT}.serving/" "${root}/Dockerfile.${PROJECT}"
		;;
	ml-ui)
		sed -i "s/ml_ui\.dummy_project\.ui/ml_ui.${PROJECT}.ui/" "${root}/Dockerfile.${PROJECT}"
		;;
	esac

	log "INFO" "${repo}: done (add tests under tests/ manually if needed)"
}

scaffold_stage ml-data ml_data data
scaffold_stage ml-training ml_training training
scaffold_stage ml-serving ml_serving serving
scaffold_stage ml-ui ml_ui ui

log "INFO" "Scaffold complete. Run lint-all and test-all on the four python repos."
