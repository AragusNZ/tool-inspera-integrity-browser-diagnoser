#!/usr/bin/env bash
# Bump VERSION, commit, tag v<version>, and push.
# Prefer: ./dev.sh version [patch|minor|major]
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ROOT="$(inspera_root "${BASH_SOURCE[0]}")"
cd "${ROOT}"

VERSION_FILE="${ROOT}/VERSION"
CHANGELOG_FILE="${ROOT}/CHANGELOG.md"

usage() {
	cat <<EOF
usage: ${INSERA_SCRIPT_NAME} [--major | --minor] [--no-push]

  Reads the current version from VERSION, increments:
    --major  first number (X.0.0)
    --minor  second number (x.Y.0)
    (default) third number (x.y.Z)

  Then promotes ## [Unreleased] in CHANGELOG.md to ## [version], commits VERSION
  and CHANGELOG.md, creates annotated tag v<version>, and pushes.
  Use --no-push to commit and tag locally only.

  Prefer from repo root: ./dev.sh version [patch|minor|major] [--no-push]

  Add release notes under ## [Unreleased] before bumping.
EOF
	exit 0
}

bump="patch"
do_push=1
while [[ "${#}" -gt 0 ]]; do
	case "${1}" in
		--major)
			[[ "${bump}" == patch ]] || die "use only one of --major, --minor"
			bump="major"
			shift
			;;
		--minor)
			[[ "${bump}" == patch ]] || die "use only one of --major, --minor"
			bump="minor"
			shift
			;;
		--no-push)
			do_push=0
			shift
			;;
		-h | --help)
			usage
			;;
		*)
			die "unknown option: ${1}"
			;;
	esac
done

[[ -r "${VERSION_FILE}" ]] || die "VERSION missing or unreadable"

read -r cur <"${VERSION_FILE}" || die "could not read VERSION"
cur="${cur//$'\r'/}"
[[ -n "${cur}" ]] || die "VERSION is empty"

core="${cur%%-*}"
core="${core%%+*}"
IFS=. read -r p1 p2 p3 _ <<<"${core}"

[[ -n "${p1}" && "${p1}" =~ ^[0-9]+$ ]] || die "cannot parse major from '${cur}'"
[[ -z "${p2}" || "${p2}" =~ ^[0-9]+$ ]] || die "cannot parse minor from '${cur}'"
[[ -z "${p3}" || "${p3}" =~ ^[0-9]+$ ]] || die "cannot parse patch from '${cur}'"

maj="${p1}"
min="${p2:-0}"
pat="${p3:-0}"

case "${bump}" in
	major)
		new_m=$((10#${maj} + 1))
		new_mm=0
		new_p=0
		;;
	minor)
		new_m=$((10#${maj}))
		new_mm=$((10#${min} + 1))
		new_p=0
		;;
	patch)
		new_m=$((10#${maj}))
		new_mm=$((10#${min}))
		new_p=$((10#${pat} + 1))
		;;
esac

ver="${new_m}.${new_mm}.${new_p}"

if [[ -n "$(git status --porcelain)" ]]; then
	die "working tree is not clean; commit or stash first"
fi

resolve_stale_version_tag "${ver}" "${cur}"

current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || die "not a git repository"
[[ "${current_branch}" != HEAD ]] || die "detached HEAD; checkout a branch before running this script"

printf '%s\n' "${ver}" >"${VERSION_FILE}"
git add "${VERSION_FILE}"

changelog_updated=0
if [[ -f "${CHANGELOG_FILE}" ]]; then
	promote_rc=0
	promote_changelog_unreleased "${ver}" "${CHANGELOG_FILE}" || promote_rc=$?
	if [[ "${promote_rc}" -eq 0 ]]; then
		git add "${CHANGELOG_FILE}"
		changelog_updated=1
	elif [[ "${promote_rc}" -eq 2 ]]; then
		info "Reminder: add release notes under ## [Unreleased] in CHANGELOG.md."
	fi
fi

git commit -m "Bump version to ${ver}"
git tag -a "v${ver}" -m "Release v${ver}"

if [[ "${do_push}" -eq 1 ]]; then
	git push
	git push origin "v${ver}"
	echo "Bumped to ${ver}; committed, tagged v${ver}, and pushed."
else
	echo "Bumped to ${ver}; committed and tagged v${ver} locally (--no-push)."
fi

if [[ "${changelog_updated}" -eq 0 ]] && [[ -f "${CHANGELOG_FILE}" ]] && ! grep -qF "## [${ver}]" "${CHANGELOG_FILE}"; then
	info "Reminder: add a ## [${ver}] section to CHANGELOG.md before publishing the GitHub release."
fi

printf '%s\n' \
	"Next: ./dev.sh build (or .\\build.cmd on Windows)," \
	"then ./dev.sh release or .scripts/commit-dist.sh to commit dist/InsperaExamHelper-${ver}.zip," \
	"then ./dev.sh github-release (or ./dev.sh release --github)." >&2
