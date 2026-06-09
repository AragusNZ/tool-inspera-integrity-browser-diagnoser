#!/usr/bin/env bash
# Run the full Inspera toolkit Pester suite (Windows PowerShell 5.1).
# Prefer: ./dev.sh test
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ROOT="$(inspera_root "${BASH_SOURCE[0]}")"

usage() {
	cat <<EOF
usage: ${INSERA_SCRIPT_NAME} [--quiet|-q]

  Run the full Pester suite via test.sh (Windows PowerShell 5.1).

  Prefer from repo root: ./dev.sh test

  INSPERA_TEST_QUIET=1  suppresses the final success line (same as --quiet).
EOF
	exit 0
}

suppress_pass_msg="${INSPERA_TEST_QUIET:-0}"
[[ "${suppress_pass_msg}" == "1" ]] || suppress_pass_msg=0

ps_args=()
for _arg in "$@"; do
	case "${_arg}" in
		-h|--help) usage ;;
		--quiet|-q) suppress_pass_msg=1 ;;
		*) ps_args+=("${_arg}") ;;
	esac
done

bash "${ROOT}/test.sh" "${ps_args[@]}"

if [[ "${suppress_pass_msg}" -eq 0 ]]; then
	echo "All ${INSERA_SCRIPT_NAME} cases passed."
fi
