#!/usr/bin/env bash
# Create a GitHub release for the current VERSION (notes from CHANGELOG.md).
# Prefer: ./dev.sh release --github
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
usage: ${INSERA_SCRIPT_NAME} [--draft]

  Create a GitHub release for tag v<version>:
    - Release notes from CHANGELOG.md (## [version] section)
    - Assets: dist/InsperaExamHelper-<version>.zip and .sha256

  Requires: gh CLI (authenticated), tag v<version> on origin, dist artifacts built.

  Prefer from repo root:
    ./dev.sh release --github
    ./dev.sh github-release

  Use --draft to publish as a draft release.
EOF
	exit 0
}

extract_changelog_notes() {
	local ver="${1:?version required}"
	local file="${2:?changelog file required}"

	awk -v ver="${ver}" '
		/^## \[/ {
			if (capturing) {
				exit
			}
			if ($0 ~ "^## \\[" ver "\\]") {
				capturing = 1
				next
			}
		}
		capturing {
			print
		}
	' "${file}"
}

draft=0
while [[ "${#}" -gt 0 ]]; do
	case "${1}" in
		--draft)
			draft=1
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

command -v gh >/dev/null 2>&1 || die "gh CLI not found (https://cli.github.com/)"
gh auth status >/dev/null 2>&1 || die "gh not authenticated (run: gh auth login)"

[[ -r "${VERSION_FILE}" ]] || die "VERSION missing or unreadable"
[[ -f "${CHANGELOG_FILE}" ]] || die "CHANGELOG.md not found"

read -r ver <"${VERSION_FILE}" || die "could not read VERSION"
ver="${ver//$'\r'/}"
[[ -n "${ver}" ]] || die "VERSION is empty"

tag="v${ver}"
zip_rel="dist/InsperaExamHelper-${ver}.zip"
sha_rel="${zip_rel}.sha256"
zip_path="${ROOT}/${zip_rel}"
sha_path="${ROOT}/${sha_rel}"

[[ -f "${zip_path}" ]] || die "missing ${zip_rel} (run ./dev.sh build first)"
[[ -f "${sha_path}" ]] || die "missing ${sha_rel} (run ./dev.sh build first)"

git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1 || \
	die "tag ${tag} not on origin; push commits and tag first"

if gh release view "${tag}" >/dev/null 2>&1; then
	die "GitHub release ${tag} already exists (see: gh release view ${tag})"
fi

notes_file="$(mktemp)"
trap 'rm -f "${notes_file}"' EXIT

extract_changelog_notes "${ver}" "${CHANGELOG_FILE}" >"${notes_file}"
if [[ ! -s "${notes_file}" ]]; then
	die "no ## [${ver}] section in CHANGELOG.md"
fi

gh_args=(
	release create "${tag}"
	--verify-tag
	--title "${tag}"
	--notes-file "${notes_file}"
	"${zip_path}"
	"${sha_path}"
)
if [[ "${draft}" -eq 1 ]]; then
	gh_args+=(--draft)
fi

release_url="$(gh "${gh_args[@]}")"
echo "GitHub release published: ${release_url}"
