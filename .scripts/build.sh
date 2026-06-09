#!/usr/bin/env bash
# Build dist/InsperaExamHelper-<version>.zip via Windows PowerShell (ps2exe).
# Prefer: ./dev.sh build
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ROOT="$(inspera_root "${BASH_SOURCE[0]}")"

usage() {
	cat <<EOF
usage: ${INSERA_SCRIPT_NAME}

  Build dist/InsperaExamHelper-<version>.zip via build.ps1 on Windows PowerShell 5.1.

  Prefer from repo root: ./dev.sh build

  Requires Windows PowerShell (native Windows or WSL interop).
  VERSION is read from the VERSION file by build.ps1.
EOF
	exit 0
}

for _arg in "$@"; do
	case "${_arg}" in
		-h|--help) usage ;;
		*)
			die "unknown option: ${_arg} (try --help)"
			;;
	esac
done

PS_EXE="$(find_windows_powershell)" || {
	printf '%s\n' \
		"${INSERA_SCRIPT_NAME}: Windows PowerShell 5.1 not found." \
		'  On Windows: run .\build.cmd from the repo root.' \
		'  On WSL: ensure Windows interop is available (/mnt/c/...).' >&2
	exit 1
}

WIN_ROOT="$(win_path "${ROOT}")"

info "running build.ps1 via ${PS_EXE}"
exec "${PS_EXE}" -NoProfile -ExecutionPolicy Bypass -File "${WIN_ROOT}\\build.ps1"
