# Changelog

All notable changes to this project are documented here, in
[Keep a Changelog](https://keepachangelog.com) format.

## [Unreleased]

## [2.0.0] - 2026-10-28

### Changed
- Rewritten in Python (PySide6, psutil, pywin32); the same four buttons, sections, catalog and fixtures. The PowerShell scripts, `.cmd` launchers, ps2exe build and `dev.sh` release scripts are gone
- Ships as a per-user Inno Setup installer (`InsperaExamHelper-<version>-setup.exe`) plus a zip, published by the `release` workflow on a `v*` tag; the zips are no longer committed to the repository
- `config.json` lives beside the exe and survives upgrades; the blocklist and error catalog are bundled
- Catalog fixes name buttons ("Click 'Prepare my PC'") instead of `.ps1` commands
- Version 2.0.0: the install path, exe name and settings location all change from 1.x. Remove the old `InsperaExamHelper` folder by hand

### Added
- Help > Check for Updates, and a silent check at startup (Help > Check on Startup to disable), against GitHub Releases
- Dark mode follows Windows
- Unhandled errors are logged to `%TEMP%\InsperaExamHelper.log` and shown with the path
- CI runs the suite on ubuntu and windows; the Windows leg runs the live Windows probes

### Fixed
- Clock accuracy check decoded the NTP reply little-endian and mixed local/UTC kinds, reporting ~1.8 billion seconds of skew on every PC
- CPU SSE4.2 check never ran (`__cpuid` is not a kernel32 export); now uses `IsProcessorFeaturePresent` with a CPU-name fallback
- Remote session check shelled out to `query session` (missing on some hosts, listener line matched on every RDP-enabled PC); now uses `SystemInformation.TerminalServerSession`
- WSL check matched against UTF-16 output with embedded nulls, so an installed-but-idle WSL warned
- Power state check missed "fully charged on AC"; now uses `SystemInformation.PowerStatus`
- Virtualization feature check needed admin; now reads `Win32_OptionalFeature`
- `./dev.sh lint --ps` passed an array to `Invoke-ScriptAnalyzer -Path` and crashed before analysing anything
- Diagnosis fix text no longer renders as "..Click 'Prepare my PC', then try Inspera again then retry"

### Added
- Checks: Windows version (64-bit, ARM, S mode), Graphics driver (basic adapter crashes IIB UI), Disk space (always; 1 GB when proctored), Inspera not already running (stale `inspera-launcher.exe`), Virtual machine, Administrator rights (info), Webcam for proctored exams (LifeCam HD-3000 warning)
- Config keys `minimumIibVersion` (default 1.15.4) and `approvedKeyboardLanguages`; IIB installation check fails on older versions and warns about a leftover Inspera Exam Portal
- ErrorCatalog entries `Configuration download failed` and `IIB already running`, with parser patterns and fixtures; remote-session wording maps to Environment failure
- Blocklist: HP desktopextension.exe, new Teams, Chrome Remote Desktop, Splashtop, LogMeIn, UltraViewer, Supremo, VNC, Xbox Game Bar, NVIDIA Share, RTSS/Afterburner, Webex, WhatsApp, vmconnect, QEMU, Loom, Snagit, Greenshot
- Targeted checks probe the `connectionCheck.json` URL recorded in the log; UI runtime errors re-check the graphics driver
- README: "What Inspera Integrity Browser requires" table and IT network allowlist, sourced from Inspera's October 2026 requirements

### Changed
- Checks carry an `Informational` flag instead of special-casing the keyboard check by name
- ErrorCatalog fixes follow current Inspera and University of Auckland guidance (Hyper-V / Virtual Machine Platform, startup apps, HP Desktop Extension, Sync now, LifeCam, firewall/antivirus for uploads)
- Exam reminders mention Remote Desktop, keyboard language and restarting before the exam
- Hyper-V / Virtual Machine Platform warning no longer counts as an issue in the readiness summary

## [1.0.6] - 2026-06-10

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
