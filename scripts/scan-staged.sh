#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Staged content is one commit away from being public. Flag anything that
# should not leave the machine before the user commits.

MAX_FILE_BYTES=$((1024 * 1024))

parse_global_flags "$@" || exit 1
resolve_target_repos "${META_REMAINING_ARGS[@]}" || exit 1

log "INFO" "ML_HOMELAB_ROOT=${ML_HOMELAB_ROOT}"

findings=0
staged_total=0

report() {
	printf "  %-12s %-44s %s\n" "$1" "$2" "$3"
	findings=$((findings + 1))
}

path_risk() {
	case "$1" in
	*.env | *.env.* | .env) echo "env file may hold credentials" ;;
	*.pem | *.key | *id_rsa* | *id_ed25519*) echo "private key material" ;;
	*.tfstate | *.tfstate.*) echo "terraform state may embed secrets" ;;
	*.tfvars | *.tfvars.json) echo "terraform variables may hold secrets" ;;
	*.terraform_envs) echo "generated environment file" ;;
	*.netrc | *.npmrc | *.pypirc) echo "tool credentials file" ;;
	*.p12 | *.pfx | *.keystore | *.jks) echo "keystore material" ;;
	*credential* | *secret* | *password*) echo "name suggests secrets" ;;
	*.pkl | *.pickle | *.joblib | *.h5 | *.onnx) echo "model artifact" ;;
	*.csv | *.parquet | *.feather) echo "data file" ;;
	*.log) echo "log file" ;;
	*) return 1 ;;
	esac
}

content_risk() {
	local diff_text="$1"
	local line pattern label
	# Fields are separated by @@ because the patterns themselves contain |
	while IFS= read -r line; do
		[[ -z "$line" ]] && continue
		pattern="${line%%@@*}"
		label="${line##*@@}"
		if grep -qE -- "$pattern" <<<"$diff_text"; then
			echo "$label"
		fi
	done <<-'PATTERNS'
		-----BEGIN [A-Z ]*PRIVATE KEY-----@@private key block
		AKIA[0-9A-Z]{16}@@aws access key id
		gh[pousr]_[A-Za-z0-9]{20,}@@github token
		github_pat_[A-Za-z0-9_]{20,}@@github fine-grained token
		xox[abprs]-[A-Za-z0-9-]{10,}@@slack token
		(api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|password)['"[:space:]]*[:=]['"[:space:]]*['"]?[A-Za-z0-9/+_-]{12,}@@hardcoded credential
		/home/[a-zA-Z0-9._-]+/@@absolute home path
		/Users/[a-zA-Z0-9._-]+/@@absolute home path
	PATTERNS
}

for repo in "${META_TARGET_REPOS[@]}"; do
	if ! repo_exists "$repo"; then
		continue
	fi
	dir="$(repo_path "$repo")"

	mapfile -t staged < <(git -C "$dir" diff --cached --name-only 2>/dev/null)
	[[ "${#staged[@]}" -eq 0 ]] && continue

	print_repo_header "$repo" "staged"
	echo "${#staged[@]} file(s)"
	staged_total=$((staged_total + ${#staged[@]}))

	for path in "${staged[@]}"; do
		[[ -z "$path" ]] && continue

		if reason="$(path_risk "$path")"; then
			report "$repo" "$path" "PATH: ${reason}"
		fi

		if [[ -f "${dir}/${path}" ]]; then
			size="$(wc -c <"${dir}/${path}" 2>/dev/null || echo 0)"
			if [[ "${size:-0}" -gt "$MAX_FILE_BYTES" ]]; then
				report "$repo" "$path" "SIZE: $((size / 1024)) KiB"
			fi
		fi

		file_diff="$(git -C "$dir" diff --cached -U0 -- "$path" 2>/dev/null)"
		[[ -z "$file_diff" ]] && continue
		while IFS= read -r label; do
			[[ -z "$label" ]] && continue
			report "$repo" "$path" "CONTENT: ${label}"
		done < <(content_risk "$file_diff")
	done
done

echo ""
if [[ "$staged_total" -eq 0 ]]; then
	echo "nothing staged"
	exit 0
fi

echo "${staged_total} staged file(s), ${findings} finding(s)"
if [[ "$findings" -gt 0 ]]; then
	echo "Review before committing. Unstage with: git -C \"\$ML_HOMELAB_ROOT/<repo>\" restore --staged <path>"
	exit 1
fi
exit 0
