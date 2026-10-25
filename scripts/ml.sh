#!/bin/bash
# Open pipeline repos in Cursor, a terminal, or print their paths.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

DRY_RUN=0

usage() {
	cat >&2 <<'EOF'
usage: ml.sh status [repos...]
       ml.sh path <repo>
       ml.sh [--dry-run] term <repo>
       ml.sh task
       ml.sh task set [--branch NAME] [--project NAME] [repos...]
       ml.sh [--dry-run] open [--task | repos...]
EOF
}

venvs_file() {
	printf '%s\n' "${ML_VENVS_FILE:-${HOME}/.config/ml-meta/venvs}"
}

task_file() {
	printf '%s\n' "${ML_TASK_FILE:-${HOME}/.config/ml-meta/task}"
}

workspace_file() {
	printf '%s\n' "${ML_WORKSPACE_FILE:-${HOME}/.config/ml-meta/workspace.code-workspace}"
}

trim() {
	local s="$1"
	s="${s#"${s%%[![:space:]]*}"}"
	s="${s%"${s##*[![:space:]]}"}"
	printf '%s' "$s"
}

expand_venv_path() {
	local p="$1"
	case "$p" in
	"~")
		p="${HOME}"
		;;
	"~/"*)
		p="${HOME}/${p:2}"
		;;
	esac
	p="${p//\$\{HOME\}/${HOME}}"
	p="${p//\$HOME/${HOME}}"
	printf '%s' "$p"
}

# Sets VENV_CONFIG_SET and VENV_CONFIG_RAW. A present key with an empty value stays set.
venv_config_lookup() {
	local repo="$1"
	local file line key val
	VENV_CONFIG_SET=0
	VENV_CONFIG_RAW=""
	file="$(venvs_file)"
	[[ -f "$file" ]] || return 0
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		line="$(trim "$line")"
		[[ -z "$line" ]] && continue
		[[ "$line" == *"="* ]] || continue
		key="$(trim "${line%%=*}")"
		val="$(trim "${line#*=}")"
		if [[ "$key" == "$repo" ]]; then
			VENV_CONFIG_SET=1
			VENV_CONFIG_RAW="$val"
			return 0
		fi
	done <"$file"
}

repo_uses_poetry() {
	local dir="$1"
	[[ -f "${dir}/pyproject.toml" ]] || return 1
	grep -q '^\[tool\.poetry\][[:space:]]*$' "${dir}/pyproject.toml"
}

poetry_env_path() {
	local dir="$1"
	local path
	command -v poetry >/dev/null 2>&1 || return 1
	path="$(poetry -C "$dir" env info -p 2>/dev/null)" || return 1
	[[ -n "$path" ]] || return 1
	printf '%s' "$path"
}

# Sets VENV_KIND and VENV_PATH. Kind is config, "config missing", .venv, poetry, or none.
resolve_venv() {
	local repo="$1"
	local dir expanded poetry_path
	dir="$(repo_path "$repo")"
	VENV_KIND="none"
	VENV_PATH=""
	venv_config_lookup "$repo"
	if [[ "$VENV_CONFIG_SET" -eq 1 ]]; then
		if [[ -z "$VENV_CONFIG_RAW" ]]; then
			VENV_KIND="config missing"
			return 0
		fi
		expanded="$(expand_venv_path "$VENV_CONFIG_RAW")"
		VENV_PATH="$expanded"
		if [[ -f "${expanded}/bin/activate" ]]; then
			VENV_KIND="config"
		else
			VENV_KIND="config missing"
		fi
		return 0
	fi
	if [[ -f "${dir}/.venv/bin/activate" ]]; then
		VENV_KIND=".venv"
		VENV_PATH="${dir}/.venv"
		return 0
	fi
	if repo_uses_poetry "$dir"; then
		if poetry_path="$(poetry_env_path "$dir")" && [[ -f "${poetry_path}/bin/activate" ]]; then
			VENV_KIND="poetry"
			VENV_PATH="$poetry_path"
			return 0
		fi
	fi
}

format_term_report() {
	local repo="$1"
	local kind="$2"
	local path="$3"
	if [[ -n "$path" ]]; then
		printf '%-14s %-6s %-16s %s\n' "$repo" "term" "$kind" "$path"
	else
		printf '%-14s %-6s %s\n' "$repo" "term" "$kind"
	fi
}

term_rc_path() {
	local repo="$1"
	local base="${XDG_RUNTIME_DIR:-/tmp}/ml-meta"
	printf '%s/term-%s.bash' "$base" "$repo"
}

write_term_rc() {
	local rc="$1"
	local activate="$2"
	local report="$3"
	local bashrc="${HOME}/.bashrc"
	mkdir -p "$(dirname "$rc")"
	{
		printf 'if [[ -f %q ]]; then\n' "$bashrc"
		printf '\tsource %q\n' "$bashrc"
		printf 'fi\n'
		printf 'source %q\n' "$activate"
		printf 'printf '\''%%s\\n'\'' %q\n' "$report"
	} >"$rc"
}

require_known_repo() {
	local repo="$1"
	if ! is_known_repo "$repo"; then
		echo "Unknown repository: ${repo}" >&2
		return 1
	fi
	if [[ ! -d "$(repo_path "$repo")" ]]; then
		echo "Missing checkout: $(repo_path "$repo")" >&2
		return 1
	fi
}

cmd_status() {
	bash "${SCRIPT_DIR}/status-all.sh" "$@"
}

cmd_path() {
	local repo="${1:-}"
	if [[ $# -ne 1 ]]; then
		echo "usage: ml.sh path <repo>" >&2
		return 1
	fi
	require_known_repo "$repo"
	repo_path "$repo"
}

# A live screen id is what makes --tab join the current window. Dropping it
# starts a new window instead. Existing tabs are left alone.
screen_is_live() {
	local screen="$1"
	[[ -n "$screen" ]] || return 1
	gdbus call --session --dest org.gnome.Terminal \
		--object-path /org/gnome/Terminal \
		--method org.freedesktop.DBus.ObjectManager.GetManagedObjects \
		2>/dev/null | grep -F -q "'${screen}'"
}

launch_terminal() {
	local dir="$1"
	local kind="$2"
	local rc="$3"
	local -a cmd
	command -v gnome-terminal >/dev/null 2>&1 || {
		echo "gnome-terminal not found" >&2
		return 1
	}
	cmd=(
		gnome-terminal --tab --active --working-directory="$dir" --
		bash
	)
	if [[ "$kind" == "config" || "$kind" == ".venv" || "$kind" == "poetry" ]]; then
		cmd+=(--rcfile "$rc")
	fi
	if screen_is_live "${GNOME_TERMINAL_SCREEN:-}"; then
		"${cmd[@]}"
	else
		env -u GNOME_TERMINAL_SCREEN -u GNOME_TERMINAL_SERVICE "${cmd[@]}"
	fi
}

cmd_term() {
	local repo="${1:-}"
	local dir kind report rc
	if [[ $# -ne 1 ]]; then
		echo "usage: ml.sh term <repo>" >&2
		return 1
	fi
	require_known_repo "$repo"
	dir="$(repo_path "$repo")"
	resolve_venv "$repo"
	kind="$VENV_KIND"
	report="$(format_term_report "$repo" "$kind" "$VENV_PATH")"
	printf '%s\n' "$report"
	rc="$(term_rc_path "$repo")"
	if [[ "$kind" == "config" || "$kind" == ".venv" || "$kind" == "poetry" ]]; then
		write_term_rc "$rc" "${VENV_PATH}/bin/activate" "$report"
	fi
	if [[ "$DRY_RUN" -eq 1 ]]; then
		if [[ "$kind" == "config" || "$kind" == ".venv" || "$kind" == "poetry" ]]; then
			printf 'gnome-terminal --tab --active --working-directory=%q -- bash --rcfile %q\n' "$dir" "$rc"
		else
			printf 'gnome-terminal --tab --active --working-directory=%q -- bash\n' "$dir"
		fi
		return 0
	fi
	launch_terminal "$dir" "$kind" "$rc"
}

TASK_BRANCH=""
TASK_PROJECT=""
TASK_REPOS=""

read_task() {
	local file line key val
	TASK_BRANCH=""
	TASK_PROJECT=""
	TASK_REPOS=""
	file="$(task_file)"
	[[ -f "$file" ]] || return 0
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		line="$(trim "$line")"
		[[ -z "$line" ]] && continue
		[[ "$line" == *"="* ]] || continue
		key="$(trim "${line%%=*}")"
		val="$(trim "${line#*=}")"
		case "$key" in
		branch) TASK_BRANCH="$val" ;;
		project) TASK_PROJECT="$val" ;;
		repos) TASK_REPOS="$val" ;;
		esac
	done <"$file"
}

write_task() {
	local file
	file="$(task_file)"
	mkdir -p "$(dirname "$file")"
	printf 'branch=%s\nproject=%s\nrepos=%s\n' "$TASK_BRANCH" "$TASK_PROJECT" "$TASK_REPOS" >"$file"
}

cmd_task() {
	local sub="${1:-}"
	if [[ -z "$sub" ]]; then
		read_task
		printf 'branch=%s\nproject=%s\nrepos=%s\n' "$TASK_BRANCH" "$TASK_PROJECT" "$TASK_REPOS"
		return 0
	fi
	if [[ "$sub" != "set" ]]; then
		echo "usage: ml.sh task set [--branch NAME] [--project NAME] [repos...]" >&2
		return 1
	fi
	shift
	local have_branch=0 have_project=0
	local branch="" project=""
	local repos=()
	local name
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--branch)
			[[ $# -ge 2 ]] || {
				echo "usage: ml.sh task set --branch NAME" >&2
				return 1
			}
			branch="$2"
			have_branch=1
			shift 2
			;;
		--project)
			[[ $# -ge 2 ]] || {
				echo "usage: ml.sh task set --project NAME" >&2
				return 1
			}
			project="$2"
			have_project=1
			shift 2
			;;
		--)
			shift
			repos+=("$@")
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			repos+=("$1")
			shift
			;;
		esac
	done
	if [[ "$have_branch" -eq 0 && "$have_project" -eq 0 && ${#repos[@]} -eq 0 ]]; then
		echo "usage: ml.sh task set [--branch NAME] [--project NAME] [repos...]" >&2
		return 1
	fi
	read_task
	if [[ "$have_branch" -eq 1 ]]; then
		TASK_BRANCH="$branch"
	fi
	if [[ "$have_project" -eq 1 ]]; then
		TASK_PROJECT="$project"
	fi
	if [[ ${#repos[@]} -gt 0 ]]; then
		for name in "${repos[@]}"; do
			if ! is_known_repo "$name"; then
				echo "Unknown repository: ${name}" >&2
				return 1
			fi
		done
		TASK_REPOS="${repos[*]}"
	fi
	write_task
	printf 'branch=%s\nproject=%s\nrepos=%s\n' "$TASK_BRANCH" "$TASK_PROJECT" "$TASK_REPOS"
}

json_escape() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	printf '%s' "$s"
}

# Fills OPEN_REPOS with ml-meta first, then the remaining names, without duplicates.
set_open_repos() {
	local name seen
	OPEN_REPOS=(ml-meta)
	for name in "$@"; do
		require_known_repo "$name"
		seen=0
		local existing
		for existing in "${OPEN_REPOS[@]}"; do
			if [[ "$existing" == "$name" ]]; then
				seen=1
				break
			fi
		done
		if [[ "$seen" -eq 0 ]]; then
			OPEN_REPOS+=("$name")
		fi
	done
}

default_open_names() {
	local name
	local names=()
	for name in "${REPOS[@]}"; do
		names+=("$name")
	done
	set_open_repos "${names[@]}"
}

write_workspace() {
	local file name path first
	file="$(workspace_file)"
	mkdir -p "$(dirname "$file")"
	{
		printf '{\n\t"folders": [\n'
		first=1
		for name in "${OPEN_REPOS[@]}"; do
			path="$(json_escape "$(repo_path "$name")")"
			if [[ "$first" -eq 1 ]]; then
				first=0
			else
				printf ',\n'
			fi
			printf '\t\t{ "path": "%s" }' "$path"
		done
		printf '\n\t]\n}\n'
	} >"$file"
}

cmd_open() {
	local use_task=0
	local names=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--task)
			use_task=1
			shift
			;;
		--)
			shift
			names+=("$@")
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			names+=("$1")
			shift
			;;
		esac
	done
	if [[ "$use_task" -eq 1 && ${#names[@]} -gt 0 ]]; then
		echo "usage: ml.sh open --task" >&2
		return 1
	fi
	if [[ "$use_task" -eq 1 ]]; then
		read_task
		if [[ -z "$(trim "$TASK_REPOS")" ]]; then
			echo "task has no repos" >&2
			return 1
		fi
		# shellcheck disable=SC2206
		names=($TASK_REPOS)
	fi
	if [[ ${#names[@]} -eq 0 ]]; then
		default_open_names
	else
		set_open_repos "${names[@]}"
	fi
	write_workspace
	printf 'open    %s\n' "${OPEN_REPOS[*]}"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		printf 'cursor -n --classic %q\n' "$(workspace_file)"
		return 0
	fi
	command -v cursor >/dev/null 2>&1 || {
		echo "cursor not found" >&2
		return 1
	}
	# The agent shell sets CURSOR_LAYOUT=unifiedAgent and VSCODE_IPC_HOOK.
	# Leaving those set makes `cursor` attach to this chat instead of an editor.
	env \
		-u CURSOR_AGENT \
		-u CURSOR_LAYOUT \
		-u CURSOR_CONVERSATION_ID \
		-u CURSOR_EXTENSION_HOST_ROLE \
		-u VSCODE_IPC_HOOK \
		cursor -n --classic "$(workspace_file)"
}

main() {
	local args=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--)
			shift
			args+=("$@")
			break
			;;
		*)
			args+=("$1")
			shift
			;;
		esac
	done
	if [[ ${#args[@]} -eq 0 ]]; then
		usage
		return 1
	fi
	set -- "${args[@]}"
	local cmd="$1"
	shift
	case "$cmd" in
	status) cmd_status "$@" ;;
	path) cmd_path "$@" ;;
	term) cmd_term "$@" ;;
	task) cmd_task "$@" ;;
	open) cmd_open "$@" ;;
	*)
		usage
		return 1
		;;
	esac
}

main "$@"
