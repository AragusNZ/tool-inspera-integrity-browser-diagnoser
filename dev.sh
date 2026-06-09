#!/usr/bin/env bash
# Inspera Toolkit developer entry point.
# Usage: ./dev.sh <command> [options]
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=.scripts/lib/common.sh
source "${ROOT}/.scripts/lib/common.sh"

SCRIPTS="${ROOT}/.scripts"

usage() {
	cat <<EOF
Inspera Toolkit — developer commands

Usage: ./dev.sh <command> [options]

Commands:
  help                          Show this help
  test [--quiet|-q]             Run Pester suite (Windows PowerShell)
  lint [--tests] [--ps] [--all] ShellCheck; optional Pester / PSScriptAnalyzer
  build                         Build dist/InsperaExamHelper-<version>.zip
  version [patch|minor|major] [--no-push]
                                Bump VERSION, commit, tag, push
  check                         lint + test (pre-commit / pre-release)
  release [--no-push]           check → version bump → build

Examples:
  ./dev.sh check
  ./dev.sh version minor
  ./dev.sh release --no-push

Advanced: .scripts/*.sh remain available for CI and scripting.
EOF
}

run_test() {
	bash "${SCRIPTS}/test.sh" "$@"
}

run_lint() {
	bash "${SCRIPTS}/lint.sh" "$@"
}

run_build() {
	bash "${SCRIPTS}/build.sh"
}

run_version() {
	local bump="patch"
	local args=()
	while [[ "${#}" -gt 0 ]]; do
		case "${1}" in
			patch|minor|major)
				bump="${1}"
				shift
				;;
			--no-push)
				args+=(--no-push)
				shift
				;;
			*)
				die "unknown option for version: ${1}"
				;;
		esac
	done
	case "${bump}" in
		major) args=(--major "${args[@]}") ;;
		minor) args=(--minor "${args[@]}") ;;
		patch) ;;
	esac
	bash "${SCRIPTS}/version-push.sh" "${args[@]}"
}

cmd_test() {
	exec bash "${SCRIPTS}/test.sh" "$@"
}

cmd_lint() {
	exec bash "${SCRIPTS}/lint.sh" "$@"
}

cmd_build() {
	exec bash "${SCRIPTS}/build.sh" "$@"
}

cmd_version() {
	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		exec bash "${SCRIPTS}/version-push.sh" --help
	fi
	run_version "$@"
}

cmd_check() {
	run_lint "$@"
	run_test --quiet
	echo "All check cases passed."
}

cmd_release() {
	local no_push=0
	while [[ "${#}" -gt 0 ]]; do
		case "${1}" in
			--no-push) no_push=1; shift ;;
			-h|--help)
				cat <<EOF
usage: ./dev.sh release [--no-push]

  Guided release workflow:
    1. Show current VERSION and CHANGELOG reminder
    2. Run check (lint + test)
    3. Bump version (patch), commit, tag (and push unless --no-push)
    4. Build dist/InsperaExamHelper-<version>.zip

  Update CHANGELOG.md before running release.
EOF
				exit 0
				;;
			*) die "unknown option for release: ${1}" ;;
		esac
	done

	local cur next_ver changelog="${ROOT}/CHANGELOG.md"
	[[ -r "${ROOT}/VERSION" ]] || die "VERSION file not found"
	read -r cur <"${ROOT}/VERSION"
	cur="${cur//$'\r'/}"

	IFS=. read -r p1 p2 p3 _ <<<"${cur}"
	p2="${p2:-0}"
	p3="${p3:-0}"
	next_ver="${p1}.$((10#${p2})).$((10#${p3} + 1))"

	info "current VERSION: ${cur}"
	if [[ -f "${changelog}" ]] && ! grep -q "## \[${next_ver}\]" "${changelog}"; then
		info "Reminder: add ## [${next_ver}] to CHANGELOG.md before publishing the GitHub release."
	fi

	run_lint
	run_test --quiet

	local version_args=()
	if [[ "${no_push}" -eq 1 ]]; then
		version_args+=(--no-push)
	fi
	run_version patch "${version_args[@]}"

	read -r cur <"${ROOT}/VERSION"
	cur="${cur//$'\r'/}"

	run_build

	local zip="${ROOT}/dist/InsperaExamHelper-${cur}.zip"
	local sha="${zip}.sha256"
	echo ""
	echo "Release build complete."
	echo "  Zip:      ${zip}"
	if [[ -f "${sha}" ]]; then
		echo "  Checksum: ${sha}"
	fi
	if [[ "${no_push}" -eq 1 ]]; then
		echo "  (version committed locally only — push tags when ready)"
	fi
	echo "  Next: attach the zip to GitHub release v${cur}"
}

main() {
	local cmd="${1:-help}"
	shift || true

	case "${cmd}" in
		help|-h|--help) usage ;;
		test) cmd_test "$@" ;;
		lint) cmd_lint "$@" ;;
		build) cmd_build "$@" ;;
		version) cmd_version "$@" ;;
		check) cmd_check "$@" ;;
		release) cmd_release "$@" ;;
		*)
			die "unknown command: ${cmd} (try: ./dev.sh help)"
			;;
	esac
}

main "$@"
