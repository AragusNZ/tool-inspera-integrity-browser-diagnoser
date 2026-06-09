#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
WIN_REPO="$(wslpath -w "$REPO")"
exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
  -NoProfile -ExecutionPolicy Bypass -File "$WIN_REPO\\test.ps1" "$@"
