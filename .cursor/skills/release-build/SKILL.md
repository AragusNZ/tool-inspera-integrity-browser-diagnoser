---
name: release-build
description: Build the Inspera Exam Helper release bundle (exe, lib, data, zip). Use when the user says build release, rebuild exe, update dist, or redistribute the toolkit.
disable-model-invocation: true
---

# Release Build

Produce `dist/InsperaExamHelper/` and `dist/InsperaExamHelper-<version>.zip` for exam PC distribution.

## Prerequisites

- **Windows** with Windows PowerShell 5.1 (not PowerShell Core)
- Network on first run (installs ps2exe from PSGallery if missing)
- Tests passing before build

## Workflow

```
- [ ] Step 1: Run tests
- [ ] Step 2: Build on Windows
- [ ] Step 3: Verify dist contents
- [ ] Step 4: Redistribute
```

Or use the guided command (update CHANGELOG first):

```bash
./dev.sh release --github    # full flow: check, bump, build, commit dist, GitHub release
./dev.sh release --no-push   # local tag; push when ready
./dev.sh release             # check, bump patch, push tag, build, commit dist
./dev.sh github-release      # publish GitHub release for current VERSION (needs gh CLI)
```

Requires `gh` CLI authenticated (`gh auth login`) for `--github` / `github-release`.
Release notes are taken from the matching `## [version]` section in `CHANGELOG.md`.

### Step 1 — Run tests

From WSL (dev):

```bash
./dev.sh test
# or: ./dev.sh check   (lint + test)
```

From Windows:

```powershell
.\test.ps1
```

Do not build if tests fail.

### Step 2 — Build on Windows

From WSL with Windows interop:

```bash
./dev.sh build
```

On Windows directly:

```powershell
.\build.cmd
```

Use `build.cmd` (not `build.ps1` directly) — bypasses execution policy on locked-down PCs.

`build.ps1` will:

1. Install/import **ps2exe** if missing
2. Compile `Inspera-Toolkit.ps1` → `dist/InsperaExamHelper/Inspera Exam Helper.exe`
3. Copy `lib/` and `data/` into dist
4. Write `README.txt` and zip to `dist/InsperaExamHelper-<version>.zip`

### Step 3 — Verify dist contents

`dist/InsperaExamHelper/` must contain:

| Item | Required |
|---|---|
| `Inspera Exam Helper.exe` | Yes |
| `lib/` (full module tree) | Yes |
| `data/` (`config.json`, `default-blocklist.json`) | Yes |
| `README.txt` | Yes |

The exe loads scripts and JSON from sibling `lib/` and `data/` at runtime. **Do not** distribute the exe alone.

### Step 4 — Redistribute

Copy `dist/InsperaExamHelper/` folder or `dist/InsperaExamHelper-<version>.zip` to exam PCs (USB, zip).

After any `lib/` or `data/` change, rebuild before redistributing.

## Notes

- Exe is unsigned (ps2exe) — some AV may flag it; README documents fallback via `Start Inspera Toolkit.cmd`
- Do not hand-edit files under `dist/` — edit source and rebuild
- `dist/` is gitignored; source of truth is `lib/`, `data/`, entry scripts
