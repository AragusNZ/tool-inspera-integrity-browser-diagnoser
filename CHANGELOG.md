# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Changed
- `./dev.sh version` and `./dev.sh release` promote `## [Unreleased]` in CHANGELOG.md to the new version on bump
- Version bump removes stale local tags left by an aborted release (not on current branch, not on origin)

### Added
- `./dev.sh release` commits distribution zip and checksum after build (`.scripts/commit-dist.sh`)
- `./dev.sh github-release` and `./dev.sh release --github` publish GitHub releases via `gh` CLI

## [1.0.5] - 2026-06-10

### Added
- Release zip and SHA256 checksum committed in git for v1.0.5

### Changed
- `.gitignore` tracks `dist/*.zip` and checksums only; other build output stays untracked

## [1.0.4] - 2026-06-10

### Changed
- `./dev.sh release` runs lint and tests before the version bump so a failed check no longer leaves a pushed tag behind

## [1.0.3] - 2026-06-10

### Fixed
- `./dev.sh test --quiet` and release check no longer pass `--quiet` through to `test.ps1` (which does not accept that parameter)

## [1.0.2] - 2026-06-10

No toolkit or developer workflow changes in this release.

## [1.0.1] - 2026-06-10

### Added
- `./dev.sh` developer entry point (`test`, `lint`, `build`, `version`, `check`, `release`)
- `.scripts/` helpers for build, test, lint, and version bump/tag/push
- ShellCheck linting in GitHub Actions and local `./dev.sh lint`

### Changed
- README documents developer commands and `./dev.sh` workflow

## [1.0.0] - 2026-06-09

### Added
- GitHub Actions workflow running the Pester suite on Windows
- Versioned release zip with SHA256 checksum and BUILD.txt metadata
- Student `.cmd` shortcuts included in release builds
- `ToolkitActions.Tests.ps1`, `Config.Tests.ps1`, and expanded smoke tests
- `Bootstrap-InsperaToolkit.ps1` shared module loader
- Shared section builders for environment and system checks
- `config.json.example` and `config.schema.json`

### Changed
- Pester sets `INSPERA_TEST_MODE` so `Prepare -Apply` does not run `wsl --shutdown` on WSL dev hosts
- Neutral default `config.json` using `%TEMP%` instead of a hardcoded user path
- Guided flow skips redundant environment/system checks after prepare
- Process blocklist diagnosis no longer shows misleading network live checks
- Pinned Pester and ps2exe versions in `requirements.psd1`

### Removed
- Unused legacy helpers (`Format-InsperaDiagnosis`, output capture, direct console audit writers)
