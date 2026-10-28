# Contributing

Inspera Exam Helper is a Windows desktop tool built on PySide6 (the window), psutil, pywin32 and ctypes (the Windows
probes) and the standard library (everything that reads a log). It ships as a PyInstaller `--onedir` build wrapped in
an Inno Setup installer.

[README.md](README.md) is the user-facing half of this document, for students and IT. [AGENTS.md](AGENTS.md) is the
same ground compressed for coding agents.

## Run from source

[uv](https://docs.astral.sh/uv/) installs everything, Python 3.12 included. Linux/WSL works for development — you
need WSLg for the window, and every Windows probe reports "skipped" there — but the exe can only be built on Windows.

```
uv sync                                  # .venv from pyproject.toml and uv.lock
uv run python -m inspera_exam_helper
```

The same two commands work on Windows, where the checks are real. A dependency change is `uv add <pkg>` (or
`uv add --group dev <pkg>`), which updates `pyproject.toml` and `uv.lock` together; commit both.

## Tests

```
uv run ruff check . && uv run ruff format --check .   # lint and formatting, as CI runs them
uv run pytest --cov                                   # the tests and the coverage floor
```

CI fails under the coverage floor in `pyproject.toml` (`.github/workflows/check.yml`), on ubuntu and windows, so a new
module lands with its test. `tests/` mirrors the source, and `tests/test_structure.py` fails a module over 300 lines,
a function over 40, a Qt import outside `ui/` and `app/`, or a `core/` module importing outside `core/`.

Three fixtures in `tests/conftest.py` keep tests off the real machine:

- `stub_probes` — every function in `core/checks/probes.py` raises, so each check takes its "skipped" branch.
- `healthy_probes` — a fake PC that passes every check, for testing a flow's own logic.
- `fake_processes('Discord.exe', ...)` — replaces the process table.

`tests/core/checks/test_live.py` is the exception: it runs the real probes and is skipped off Windows.
`INSPERA_SKIP_WSL_SHUTDOWN=1` is set for the whole suite so no test ever runs `wsl --shutdown` on a dev host.

Qt runs offscreen: `QT_QPA_PLATFORM=offscreen`, and the `qapp` fixture is the single `QApplication` for the session.
Never construct a second one.

## Layout

```
inspera_exam_helper/
  app/            the window, settings, the update check, main() — wires the rest together
  core/           no Qt import anywhere
    logs/         lines.py (one line -> fields), patterns.py (the failure vocabulary), parser.py (ParsedLog,
                  primary-failure choice), details.py (apps, metadata, check events), discovery.py (which log)
    checks/       probes.py (every Windows call, coverage-omitted) and four decision modules beside it;
                  __init__.py says which checks run for which flow
    flows/        prepare, preflight, diagnose, guided: each has run(ctx) -> Result; sections.py is shared
    processes.py  blocklist merge, running matches, stop, wsl --shutdown
    config.py / paths.py / catalog.py / result.py / update.py
  data/           config.json (default), default-blocklist.json, error_catalog.json, config.schema.json
  assets/         icon.ico and the SVGs it is generated from
ui/               worker.py (QThread runner), theme.py (palette + stylesheet)
tools/make_icon.py  regenerates assets/icon.ico from the SVGs
tests/            pytest, mirroring the source; fixtures/ holds real and synthetic IIB logs
packaging/inspera-exam-helper.iss  the Inno Setup installer, compiled by build.ps1
```

`core/` is importable from a script or a test with no Qt in sight; that separation is the point of the split.

## How a button works

Every button builds a `Context` (`flows.context()`: the config, the newest log parsed once, the URL to probe) and
hands `flows.<name>.run(ctx)` to a `Worker` thread. `run` returns a `Result` — a status, a one-line summary and a list
of `Section`s, each a heading, lines and a level. The window colours lines by their `[PASS]` / `[FAIL]` / `[WARN]`
prefix, falling back to the section's level. Nothing in a flow touches Qt.

## Adding a failure type

A failure type is a regex the parser matches, a catalog entry the student reads, and a fixture that proves it.

1. Add a `FailurePattern` to `core/logs/patterns.py`. The key is the catalog key. Priority only matters when one log
   carries several failures: a runtime failure such as `desktop changed` (20) outranks the system-check failure (10)
   it usually drags along. `select_primary` in `parser.py` is the tie-break: known over `unknown`, ERROR over WARN,
   then priority, then the latest line.
2. Add the entry to `data/error_catalog.json`: `title`, `userMessage`, `fixes`. Fixes name buttons, never commands
   — "Click 'Prepare my PC', then try Inspera again". `tests/core/logs/test_patterns.py` fails on a key without an
   entry, and on any fix that mentions a `.ps1`.
3. If a live check relates, map the key in `targeted_checks` in `core/checks/__init__.py`.
4. Put a log under `tests/fixtures/` and a case in `tests/core/logs/test_parser.py`. Real logs are better than
   synthetic ones; strip the student's name and session if you have to.

## Adding a check

A check is a function returning `Check` (`core/result.py`: name, passed, message, optional warnings, an
`informational` flag that renders as `[INFO]`). Split it in two:

- the Windows call goes in `core/checks/probes.py` as a thin function returning plain values — a dict from WMI, an
  int, a list of names. `probes.py` is coverage-omitted and never imported by a test directly.
- the decision goes in the module it belongs to (`platform`, `hardware`, `network`, `software`) and calls
  `probes.<name>()` inside the same try/except shape the others use. A probe that cannot run is "skipped" with
  `passed=True` unless the check is something the PC genuinely cannot do without (memory, clock, network).

Register it in `system_checks` (the readiness list) or `environment_audit` (remote session, VM, WSL, Hyper-V) in
`core/checks/__init__.py`, and test the decision in `tests/core/checks/test_decisions.py` with the probe
monkeypatched. Add it to `healthy_probes` in `tests/conftest.py` if a flow test should see it pass.

## Conventions that bite

- **No Qt outside `ui/` and `app/`, and `core/` imports only `core/`.** `test_structure.py` enforces both.
- **Regexes are case-insensitive** (`re.I`), and every name lookup lowercases both sides. The PowerShell original
  was case-insensitive everywhere and the fixtures depend on it.
- **One `re.search` per decision.** The original's shared `$Matches` was a source of bugs; do not recreate it with a
  reused match object.
- **Parse the log once.** Every flow reads `ctx.log`, never the file.
- **Student-facing copy stays plain.** `flows/reminders.py`, the catalog and every `Check.message` are what the
  student reads. Technical detail goes in the README's IT section or here.
- **Tracebacks go to `InsperaExamHelper.log`** in the system temp folder — the exe has no console, so an exception
  that only reaches stderr is an exception nobody ever sees.
- **The icon is generated.** After editing `inspera_exam_helper/assets/icon.svg` or `icon-16.svg`, run
  `uv run python tools/make_icon.py` and commit `assets/icon.ico`.
- **Never hardcode or bump the version.** The root `VERSION` file is the only source; `inspera_exam_helper/__init__.py`
  reads it and `build.ps1` bundles it. A bump is the operator's `dt patch`.
- **Record visible changes** in `CHANGELOG.md` under `## [Unreleased]`, in
  [Keep a Changelog](https://keepachangelog.com) form.

## Build the exe

Always built with Windows Python — PyInstaller cannot cross-compile.

Both need [uv](https://docs.astral.sh/uv/) on the Windows `PATH`: `winget install astral-sh.uv`.

- From WSL: `./build.sh`. It runs `build.ps1` under Windows PowerShell; the venv and build directory go to
  `%LOCALAPPDATA%\inspera-exam-helper`, because a venv over `\\wsl.localhost` is unusably slow.
- From Windows: double-click `build.cmd`, or run `build.ps1`.

Inno Setup 6 builds the installer: `winget install JRSoftware.InnoSetup`. Without it the build still runs and just
skips that one step.

Output in `dist\`:

| File | What it is |
|---|---|
| `InsperaExamHelper\InsperaExamHelper.exe` + `_internal\` | the app itself, a `--onedir` build |
| `InsperaExamHelper-<version>-setup.exe` | the installer — what you hand to anyone else |
| `InsperaExamHelper-<version>.zip` | the same folder zipped, for a machine that cannot run an installer |
| `SHA256SUMS.txt` | checksums of both |

`build.ps1` copies `README.md`, `LICENSE` and `config.json` into `dist\InsperaExamHelper\`. The installer writes
`config.json` only when it is absent (`onlyifdoesntexist`), so IT's edits survive an upgrade.

### Why the build looks the way it does

The exe is unsigned, so everything Windows reads as trust or as an antivirus heuristic is deliberate. Do not undo
one of these to shorten the build:

- **`--onedir`, not `--onefile`.** A onefile bootloader unpacks a Python runtime into `%TEMP%` on every launch,
  which is the PyInstaller behaviour antivirus flags hardest.
- **`--noupx`.** The other heuristic.
- **`--version-file`**, generated from `VERSION`. Without it the exe has no publisher string at all and SmartScreen
  has nothing to name.
- **`PrivilegesRequired=lowest`** in `packaging/inspera-exam-helper.iss`. Per-user install, so the installer never
  triggers UAC — one less trust dialog on an unsigned build.
- **`AppId` in the `.iss` is fixed forever.** It is what makes the next version upgrade this one in place.
- **`LicenseFile=..\LICENSE`** in the `.iss` puts the MIT text on a wizard page before the install.

## Releasing

1. Write the notes under `## [Unreleased]` in `CHANGELOG.md`.
2. `dt patch` (or `dt minor` / `dt major`): bumps `VERSION`, promotes the changelog section, commits, tags
   `v<version>` and pushes.
3. `.github/workflows/release.yml` refuses a tag that does not match `VERSION`, runs the same gate as `check.yml`
   on a Windows runner, builds, and publishes the installer, zip and checksums as a GitHub release.

Never cut a release by copying `dist\` around. SmartScreen tracks reputation per file hash and per download source,
so a hand-copied exe starts from zero every time.

## Pull requests

- `uv run ruff check .`, `uv run ruff format --check .` and `uv run pytest --cov` green.
- A `CHANGELOG.md` entry under `## [Unreleased]` for anything a student or IT would notice.
- No version bump in the diff.
- No new dependency for something the standard library, psutil or pywin32 already do.

## Licence

MIT, `Copyright (c) AragusNZ` — deliberately yearless, so there is nothing to bump. That one string in
`LICENSE` is the source; `build.ps1` stamps the same wording into the exe's `LegalCopyright` field. Contribute
under it, and do not put a personal name or a year in either place.
