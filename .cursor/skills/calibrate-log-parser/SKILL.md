---
name: calibrate-log-parser
description: Calibrate the Inspera log parser with real or synthetic fixtures. Use when the user says calibrate log, parser doesn't detect, add log format, or provides an inspera-launcher-*.log file.
---

# Calibrate Log Parser

Extend parser coverage so `diagnose.ps1` detects failures from new or real IIB log formats.

## Prerequisites

- Log file: real `inspera-launcher-*.log` from `%TEMP%` or existing fixture
- Rules: [pester-tests.mdc](../../rules/pester-tests.mdc), [powershell-modules.mdc](../../rules/powershell-modules.mdc)
- Format reference: [reference.md](reference.md)

## Workflow

Copy this checklist and track progress:

```
- [ ] Step 1: Add fixture
- [ ] Step 2: Reproduce failure (diagnose or Pester)
- [ ] Step 3: Fix parser chain
- [ ] Step 4: Add Pester test
- [ ] Step 5: ErrorCatalog if new failure key
- [ ] Step 6: Run ./test.sh
```

### Step 1 — Add fixture

Copy log to `tests/fixtures/<descriptive-name>.log`. Use a name that hints at the failure (e.g. `clock-failure.log`, `real-auckland-1781002029.log`).

### Step 2 — Reproduce

**WSL (tests):** add a failing `It` block first, or run existing tests to see gap.

**Windows (full diagnose):**

```powershell
.\diagnose.ps1 -LogPath .\tests\fixtures\<name>.log -VerboseReport
```

Note: expected `PrimaryFailure.Key`, extracted `Applications`, and any "No clear failure found" outcome.

### Step 3 — Fix parser chain

Edit in this order:

| Order | File | Role |
|---|---|---|
| 1 | `lib/LogParser/Parse-InsperaLogLine.ps1` | Normalize raw line → timestamp, level, module, message |
| 2 | `lib/LogParser/Get-InsperaFailurePatterns.ps1` | Regex/patterns that map lines to failure keys |
| 3 | `lib/LogParser/Select-InsperaPrimaryFailure.ps1` | Pick primary failure when multiple match |
| 4 | `lib/LogParser/Parse-InsperaLog.ps1` | Integration: applications, system checks, timeline |

Prefer extending existing patterns over new parallel logic.

### Step 4 — Add Pester test

In `tests/LogParser.Tests.ps1`:

```powershell
It 'Detects <failure> from <fixture>' {
    $log = Join-Path $fixtures '<descriptive-name>.log'
    $result = Parse-InsperaLog -LogPath $log
    $result.Found | Should -Be $true
    $result.PrimaryFailure.Key | Should -Be '<expected-key>'
}
```

Add assertions for `$result.Applications` or `$result.FailureDetails` when relevant.

### Step 5 — New failure key?

If the failure key is not in `lib/ErrorCatalog.json`, run skill **add-failure-type** before finishing.

### Step 6 — Run tests

```bash
./test.sh
# or filtered:
./test.sh -Filter 'Parse-InsperaLog'
```

All tests must pass before considering the calibration complete.

## Additional resources

- Supported formats: [reference.md](reference.md)
- Real example: `.example/inspera-launcher-1781002029.log`
