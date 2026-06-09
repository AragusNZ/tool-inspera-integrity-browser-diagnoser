#!/usr/bin/env bash
# Lint helper scripts (ShellCheck) and optionally PowerShell (PSScriptAnalyzer).
# Prefer: ./dev.sh lint
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ROOT="$(inspera_root "${BASH_SOURCE[0]}")"
cd "${ROOT}"

GITHUB_REPO="https://github.com/AragusNZ/tool-inspera-integrity-browser-diagnoser"

run_shellcheck() {
	command -v shellcheck >/dev/null 2>&1 || {
		die "shellcheck not found (e.g. apt install shellcheck)"
	}
	shellcheck \
		dev.sh \
		test.sh \
		.scripts/lib/common.sh \
		.scripts/build.sh \
		.scripts/test.sh \
		.scripts/lint.sh \
		.scripts/commit-dist.sh \
		.scripts/version-push.sh
}

run_psscriptanalyzer() {
	local ps_exe win_root
	ps_exe="$(find_windows_powershell)" || die "Windows PowerShell not found; skip --ps or run on Windows."
	win_root="$(win_path "${ROOT}")"

	"${ps_exe}" -NoProfile -ExecutionPolicy Bypass -Command "
		\$ErrorActionPreference = 'Stop'
		Set-Location '${win_root}'
		try {
			Import-Module PSScriptAnalyzer -ErrorAction Stop
		} catch {
			Write-Host 'Installing PSScriptAnalyzer for CurrentUser...'
			Install-Module PSScriptAnalyzer -Scope CurrentUser -Force -Repository PSGallery
			Import-Module PSScriptAnalyzer -ErrorAction Stop
		}
		\$paths = @(
			'*.ps1',
			'lib',
			'tests'
		)
		\$issues = Invoke-ScriptAnalyzer -Path \$paths -Recurse -Severity Warning, Error
		if (\$issues) {
			\$issues | Format-Table -AutoSize
			exit 1
		}
		Write-Host 'PSScriptAnalyzer: no Warning/Error issues'
	"
}

run_tests() {
	bash "${ROOT}/.scripts/test.sh" --quiet
}

usage() {
	printf '%s\n' \
		"Usage: ${INSERA_SCRIPT_NAME} [--tests|-t] [--ps] [--all]" \
		"       ./dev.sh lint [options]" \
		"" \
		"  (default)  ShellCheck on dev.sh, test.sh, and .scripts/*." \
		"  --tests    Also run Pester via Windows PowerShell." \
		"  --ps       Also run PSScriptAnalyzer on .ps1 files." \
		"  --all      ShellCheck, Pester tests, and PSScriptAnalyzer" \
		"" \
		"Project: Inspera Toolkit — ${GITHUB_REPO}"
	exit 0
}

do_tests=0
do_ps=0
for _arg in "$@"; do
	case "${_arg}" in
		--tests|-t) do_tests=1 ;;
		--ps) do_ps=1 ;;
		--all) do_tests=1; do_ps=1 ;;
		-h|--help) usage ;;
		*)
			die "unknown option: ${_arg} (try --help)"
			;;
	esac
done

run_shellcheck
printf '%s\n' "${INSERA_SCRIPT_NAME}: ShellCheck OK"
if [[ "${do_tests}" -eq 1 ]]; then
	run_tests
fi
if [[ "${do_ps}" -eq 1 ]]; then
	run_psscriptanalyzer
fi
