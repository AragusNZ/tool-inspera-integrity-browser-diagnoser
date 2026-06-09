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
  release [--no-push] [--github] [--draft]
                                check → bump → build → commit dist [→ GitHub release]
  github-release [--draft]      Publish GitHub release for current VERSION

Examples:
  ./dev.sh check
  ./dev.sh version minor
  ./dev.sh release --github
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

run_commit_dist() {
	bash "${SCRIPTS}/commit-dist.sh" "$@"
}

run_github_release() {
	bash "${SCRIPTS}/github-release.sh" "$@"
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
	local do_github=0
	local gh_args=()
	while [[ "${#}" -gt 0 ]]; do
		case "${1}" in
			--no-push) no_push=1; shift ;;
			--github) do_github=1; shift ;;
			--draft)
				gh_args+=(--draft)
				shift
				;;
			-h|--help)
				cat <<EOF
usage: ./dev.sh release [--no-push] [--github] [--draft]

  Guided release workflow:
    1. Show current VERSION and CHANGELOG reminder
    2. Run check (lint + test)
    3. Bump version (patch), commit, tag (and push unless --no-push)
    4. Build dist/InsperaExamHelper-<version>.zip
    5. Commit dist zip + .sha256 (and push unless --no-push)
    6. With --github: publish GitHub release (notes from CHANGELOG.md)

  Add release notes under ## [Unreleased] in CHANGELOG.md before running release.
  --github requires a pushed tag (cannot combine with --no-push).
EOF
				exit 0
				;;
			*) die "unknown option for release: ${1}" ;;
		esac
	done

	if [[ "${do_github}" -eq 1 && "${no_push}" -eq 1 ]]; then
		die "cannot use --github with --no-push; push first, then ./dev.sh github-release"
	fi
	if [[ "${#gh_args[@]}" -gt 0 && "${do_github}" -eq 0 ]]; then
		die "--draft requires --github (or use ./dev.sh github-release --draft)"
	fi

	local cur changelog="${ROOT}/CHANGELOG.md"
	[[ -r "${ROOT}/VERSION" ]] || die "VERSION file not found"
	read -r cur <"${ROOT}/VERSION"
	cur="${cur//$'\r'/}"

	info "current VERSION: ${cur}"
	if [[ -f "${changelog}" ]] && ! grep -qF "## [Unreleased]" "${changelog}"; then
		info "Reminder: add a ## [Unreleased] section to CHANGELOG.md for release notes."
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

	local dist_args=()
	if [[ "${no_push}" -eq 1 ]]; then
		dist_args+=(--no-push)
	fi
	run_commit_dist "${dist_args[@]}"

	if [[ "${do_github}" -eq 1 ]]; then
		run_github_release "${gh_args[@]}"
	fi

	local zip="${ROOT}/dist/InsperaExamHelper-${cur}.zip"
	local sha="${zip}.sha256"
	echo ""
	echo "Release build complete."
	echo "  Zip:      ${zip}"
	if [[ -f "${sha}" ]]; then
		echo "  Checksum: ${sha}"
	fi
	if [[ "${no_push}" -eq 1 ]]; then
		echo "  (version and dist committed locally only — push when ready)"
	elif [[ "${do_github}" -eq 0 ]]; then
		echo "  Next: ./dev.sh github-release (or re-run with --github)"
	fi
}

cmd_github_release() {
	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		exec bash "${SCRIPTS}/github-release.sh" --help
	fi
	exec bash "${SCRIPTS}/github-release.sh" "$@"
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
		github-release) cmd_github_release "$@" ;;
		*)
			die "unknown command: ${cmd} (try: ./dev.sh help)"
			;;
	esac
}

main "$@"
