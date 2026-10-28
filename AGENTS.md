# inspera-exam-helper

**Project type:** python-tool

<!-- The line above is prose. The project type is declared in .dev-tools/config.json,
     which is what `dt agents wire` and the rest of dev-tools both read.
     Shipping status is NOT declared here — it is the `shipped` key in .dev-tools/config.json,
     which is the only source of truth. A missing key reads as Shipped. -->

Conventions load automatically from `~/dev/ai-agents`:

- **Claude**: channel rules via `.claude/rules/`, skills/agents via the `python-tool@aragusnz` plugin.
- **Cursor**: rules, skills, agents and the guard via `.cursor/`.

Both are generated from one source; edit `~/dev/ai-agents`, never the delivered files.

## What this is

A Windows desktop tool for students sitting exams in Inspera Integrity Browser (IIB): close the apps IIB refuses
to run beside, run the same readiness checks IIB will, and read IIB's own launcher log to say in plain words why it
failed last time. PySide6 for the window, psutil/pywin32/ctypes for the Windows probes, stdlib for the parsing.
Distributed as a PyInstaller onedir build wrapped in an Inno Setup installer, cut by the `release` workflow on a
`v*` tag.

`README.md` is user-facing only (students and IT) and `build.ps1` copies it into the shipped build, so nothing about
building or contributing belongs in it. `CONTRIBUTING.md` is the human long form of this file.

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
tests/            pytest, mirroring the source; fixtures/ holds real and synthetic IIB logs;
                  test_structure.py enforces the size caps and the Qt boundary
packaging/inspera-exam-helper.iss  the Inno Setup installer, compiled by build.ps1
```

The exe is unsigned, so everything about the build that Windows reads as trust or as an antivirus
heuristic is deliberate: `--onedir` (not onefile), `--noupx`, the `--version-file` resource `build.ps1`
generates from `VERSION`, and `PrivilegesRequired=lowest` in the `.iss`. Do not undo one of those to shorten the build.

`VERSION` at the root is the only version source. `inspera_exam_helper/__init__.py` reads it and `build.ps1`
bundles it into the exe. Never hardcode it, and never bump it — a bump is the operator's `dt patch`.

## Adding a failure type

1. Add a `FailurePattern` to `core/logs/patterns.py`. The key is the catalog key; priority only matters when one
   log carries several failures (runtime failures outrank the system-check failure they drag along).
2. Add the entry to `data/error_catalog.json`: `title`, `userMessage`, `fixes` (button names, never commands —
   "Click 'Prepare my PC', then try Inspera again"). `tests/core/logs/test_patterns.py` fails without it.
3. If a live check relates, map the key in `targeted_checks` in `core/checks/__init__.py`.
4. Add a fixture log under `tests/fixtures/` and a case in `tests/core/logs/test_parser.py`. The fixture is the spec.

## Adding a check

A check is a function returning `Check` (`core/result.py`). Split it in two: the Windows call goes in
`core/checks/probes.py` as a thin function returning plain values, the decision goes in the module that fits
(`platform`, `hardware`, `network`, `software`) and calls `probes.<name>()`. Tests monkeypatch the probe; see
`tests/core/checks/test_decisions.py`. Register it in `system_checks` or `environment_audit` in
`core/checks/__init__.py`. A probe that cannot run is "skipped", not a failed PC — follow the existing try/except shape.

## Conventions that bite

- **No Qt outside `ui/` and `app/`, and `core/` imports only `core/`.** `test_structure.py` enforces both.
- **Flows run on a worker thread.** `app/window.py` wraps `flows.<name>.run(context())` in `ui/worker.Worker`;
  nothing in `core/` may touch Qt.
- **Regexes are case-insensitive** (`re.I`) and name lookups lowercase both sides — the PowerShell original was
  case-insensitive everywhere and the fixtures depend on it.
- **One `re.search` per decision.** Never carry a match object from one test to the next.
- **Parse the log once.** `flows.context()` builds a `ParsedLog`; every flow reads that, never the file.
- **Tests never shut down WSL.** `tests/conftest.py` sets `INSPERA_SKIP_WSL_SHUTDOWN=1`; `processes.wsl_shutdown`
  honours it. The `stub_probes` / `healthy_probes` fixtures keep tests off the real machine; only
  `tests/core/checks/test_live.py` runs the real probes, on Windows.
- **Tracebacks go to `InsperaExamHelper.log`** in the system temp folder — the exe has no console.
- **Student-facing copy stays plain.** `flows/reminders.py` and the catalog are what the student reads.
- **The icon is generated.** After editing `icon.svg` or `icon-16.svg`, run `uv run python tools/make_icon.py`
  and commit `assets/icon.ico`.

## Verify

```
uv sync                    # .venv from pyproject.toml and uv.lock
uv run ruff check . && uv run ruff format --check .
uv run pytest --cov        # tests, the structure caps and the coverage floor
```

CI (`check.yml`) runs that on ubuntu and windows; the Windows leg is where `test_live.py` runs rather than skips.

The exe is built with Windows Python (PyInstaller cannot cross-compile): `./build.sh` from WSL, or
`build.cmd` / `build.ps1` from Windows.
