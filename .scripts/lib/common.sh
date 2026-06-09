# Shared helpers for Inspera Toolkit bash scripts.
# Source from .scripts/*.sh or dev.sh — do not execute directly.

inspera_root() {
	local script_path="${1:?inspera_root: script path required}"
	cd "$(dirname "${script_path}")/.." && pwd
}

find_windows_powershell() {
	if [[ -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ]]; then
		echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
	elif command -v powershell.exe >/dev/null 2>&1; then
		command -v powershell.exe
	else
		return 1
	fi
}

win_path() {
	local path="${1:?win_path: path required}"
	if command -v wslpath >/dev/null 2>&1; then
		wslpath -w "${path}"
	else
		printf '%s' "${path}"
	fi
}

die() {
	echo "${INSERA_SCRIPT_NAME:-script}: $*" >&2
	exit 1
}

info() {
	echo "${INSERA_SCRIPT_NAME:-script}: $*" >&2
}
