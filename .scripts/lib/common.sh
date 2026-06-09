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

# Promote ## [Unreleased] to ## [version] - date and insert a fresh ## [Unreleased] header.
# Returns 0 on success, 1 if the file is missing or the version section already exists,
# 2 if there is no ## [Unreleased] section to promote.
promote_changelog_unreleased() {
	local ver="${1:?promote_changelog_unreleased: version required}"
	local file="${2:?promote_changelog_unreleased: file required}"

	[[ -f "${file}" ]] || return 1

	if grep -qF "## [${ver}]" "${file}"; then
		return 0
	fi

	if ! grep -qF "## [Unreleased]" "${file}"; then
		return 2
	fi

	local date tmp
	date="$(date +%Y-%m-%d)"
	tmp="$(mktemp)"
	# shellcheck disable=SC2064
	trap "rm -f '${tmp}'" RETURN

	awk -v ver="${ver}" -v date="${date}" '
		BEGIN { after_intro_blank = 0; promoted = 0 }
		/^All notable changes to this project are documented in this file\./ {
			print
			after_intro_blank = 1
			next
		}
		after_intro_blank == 1 && $0 ~ /^$/ {
			print
			print "## [Unreleased]"
			print ""
			after_intro_blank = 2
			next
		}
		$0 ~ /^## \[Unreleased\]/ {
			print "## [" ver "] - " date
			promoted = 1
			next
		}
		{ print }
		END { if (!promoted) exit 2 }
	' "${file}" >"${tmp}" || return 2

	mv "${tmp}" "${file}"
	trap - RETURN
	return 0
}
