# Changelog

All notable changes to this project are documented in this file.

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
