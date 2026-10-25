# Source from ~/.bashrc so `ml cd` can change the current shell.
# bash scripts/ml.sh cannot do that: a child process cannot cd its parent.

ml() {
	local here script dest arg cmd dry
	here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	script="${here}/../ml.sh"
	if [[ "${1:-}" == "cd" ]]; then
		if [[ $# -ne 2 ]]; then
			echo "usage: ml cd <repo>" >&2
			return 1
		fi
		dest="$(bash "$script" path "$2")" || return
		cd "$dest" || return
		return 0
	fi
	cmd=""
	dry=0
	for arg in "$@"; do
		if [[ "$arg" == "--dry-run" ]]; then
			dry=1
			continue
		fi
		if [[ -z "$cmd" ]]; then
			cmd="$arg"
		fi
	done
	bash "$script" "$@" || return
	# Cursor opens with ml-meta first. Land this shell there too.
	if [[ "$cmd" == "open" && "$dry" -eq 0 ]]; then
		dest="$(bash "$script" path ml-meta)" || return
		cd "$dest" || return
	fi
}
