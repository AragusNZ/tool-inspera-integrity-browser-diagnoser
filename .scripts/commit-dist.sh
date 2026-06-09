#!/usr/bin/env bash
# Commit versioned dist zip + checksum for the current VERSION.
# Prefer: ./dev.sh release (runs this after build)
set -euo pipefail

INSERA_SCRIPT_NAME="$(basename "$0")"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ROOT="$(inspera_root "${BASH_SOURCE[0]}")"
cd "${ROOT}"

VERSION_FILE="${ROOT}/VERSION"

usage() {
	cat <<EOF
usage: ${INSERA_SCRIPT_NAME} [--no-push]

  Commit dist/InsperaExamHelper-<version>.zip and .sha256 for the current VERSION.

  Prefer from repo root: ./dev.sh release (check → bump → build → commit dist)

  Use --no-push to commit locally only.
EOF
	exit 0
}

do_push=1
while [[ "${#}" -gt 0 ]]; do
	case "${1}" in
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

read -r ver <"${VERSION_FILE}" || die "could not read VERSION"
ver="${ver//$'\r'/}"
[[ -n "${ver}" ]] || die "VERSION is empty"

zip_rel="dist/InsperaExamHelper-${ver}.zip"
sha_rel="${zip_rel}.sha256"
zip_path="${ROOT}/${zip_rel}"
sha_path="${ROOT}/${sha_rel}"

[[ -f "${zip_path}" ]] || die "missing ${zip_rel} (run ./dev.sh build first)"
[[ -f "${sha_path}" ]] || die "missing ${sha_rel} (run ./dev.sh build first)"

git add "${zip_rel}" "${sha_rel}"

if git diff --cached --quiet; then
	info "dist artifacts already committed for v${ver}"
	exit 0
fi

git commit -m "v${ver} Distribution Files"

if [[ "${do_push}" -eq 1 ]]; then
	git push
	echo "Committed and pushed v${ver} distribution files."
else
	echo "Committed v${ver} distribution files locally (--no-push)."
fi
