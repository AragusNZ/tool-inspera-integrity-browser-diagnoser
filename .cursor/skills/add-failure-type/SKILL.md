---
name: add-failure-type
description: Add a new IIB failure type to ErrorCatalog with parser patterns and targeted checks. Use when adding ErrorCatalog entries, new failure keys, or live re-checks for a diagnosis outcome.
disable-model-invocation: true
---

# Add Failure Type

Wire a new or missing failure key through catalog, parser, checks, and tests.

## When to use

- New failure key discovered during log calibration
- ErrorCatalog entry missing for a known IIB check
- Diagnosis shows a failure but no student-friendly explanation or live re-check

## Inputs

- Failure key (exact string, e.g. `Clock accuracy - failure`)
- Optional: fixture log in `tests/fixtures/`
- Rules: [domain-data.mdc](../../rules/domain-data.mdc)

## Workflow

```
- [ ] Step 1: ErrorCatalog entry
- [ ] Step 2: Parser patterns (if log-derived)
- [ ] Step 3: Targeted checks (if live re-check needed)
- [ ] Step 4: Tests
- [ ] Step 5: README one-liner (optional)
- [ ] Step 6: Run ./test.sh
```

### Step 1 — ErrorCatalog entry

Add to `lib/ErrorCatalog.json`:

```json
"Failure Key - failure": {
  "title": "Short title",
  "userMessage": "Plain explanation for students",
  "causes": ["Likely cause 1", "Likely cause 2"],
  "fixes": [
    "Actionable step students can take",
    "Run: .\\prepare.ps1 -Apply"
  ]
}
```

Loaded by `Get-InsperaErrorCatalog`. Keep `userMessage` and `fixes` non-technical.

### Step 2 — Parser patterns

If the failure appears in logs, extend `lib/LogParser/`:

1. `Get-InsperaFailurePatterns.ps1` — add pattern → key mapping
2. `Parse-InsperaLogLine.ps1` — only if new line format
3. `Select-InsperaPrimaryFailure.ps1` — if priority rules needed

Add fixture + `It` in `tests/LogParser.Tests.ps1`. Or run skill **calibrate-log-parser** for full parser workflow.

### Step 3 — Targeted checks

If diagnose should re-run live checks for this failure, add a `switch` case in `lib/SystemChecks/Invoke-InsperaTargetedChecks.ps1`:

```powershell
'Failure Key - failure' {
    $checks.Add((Test-InsperaSomeCheck))
}
```

New check functions go in `lib/SystemChecks/Test-Inspera*.ps1` and may also wire into `Invoke-InsperaSystemChecks.ps1` for full audits.

Test in `tests/SystemChecks.Tests.ps1`:

```powershell
It 'Maps <key> to targeted checks' {
    $results = Invoke-InsperaTargetedChecks -FailureKey '<key>'
    @($results | Where-Object { $_.Name -eq '<check-name>' }).Count | Should -Be 1
}
```

### Step 4 — Tests

Minimum: ErrorCatalog key resolvable + parser or targeted-check test. Run `./test.sh`.

### Step 5 — README (optional)

Add the failure to the "Failure types covered" list in `README.md` if it is a new category.

### Step 6 — Verify

```bash
./test.sh
```

On Windows, optionally smoke-test:

```powershell
.\diagnose.ps1 -LogPath .\tests\fixtures\<fixture>.log -VerboseReport
```
