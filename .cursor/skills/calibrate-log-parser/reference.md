# IIB Log Format Reference

Parser chain: `Parse-InsperaLogLine` → `Get-InsperaFailurePatterns` → `Select-InsperaPrimaryFailure` → `Parse-InsperaLog`.

## Supported line formats

### IIB Go launcher (primary real format)

```
2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3
```

Timestamp: `YYYY/MM/DD HH:MM:SS`. Message is remainder of line.

### iceworm component

```
iceworm: Info: ...
iceworm: Error: ...
iceworm exited: exit status 1
```

Module set to `iceworm`. Non-zero exit → ERROR.

### UI runtime crashes

```
Fyne error: GLFW poll event error: ...
GLFW poll event error
cancellation detected
```

Treated as ERROR-level runtime failures.

### electron-log

```
[2026-03-15 09:12:34.123] [error] Environment - failure
[2026-03-15 09:12:34.123] [info] message
```

Bracketed timestamp + level + message.

### Structured module (SEB-style)

```
2026-03-15 09:12:01.005 [01] - ERROR: [SystemCheck] Process blocklist - failure
2026-03-15 09:12:01.005 [01] - INFO: [Module] message
```

Optional `[Module]` between level and message.

### JSON lines

```json
{"level":"error","message":"Clock accuracy - failure"}
```

Parsed as JSON; `level` and `message` extracted.

### Official check results (plain text)

```
Environment - success
Environment - failure
Check "Environment" failed
```

Mapped directly to IIB system check names.

## Failure keys

Keys must match `lib/ErrorCatalog.json` and IIB check names, e.g.:

- `Environment - failure`
- `Process blocklist - failure`
- `Connection quality - failure`
- `Clock accuracy - failure`
- `Number of screens - failure`
- `failed to close` (runtime, not a system check name)

Full catalog: `lib/ErrorCatalog.json`.

## Fixtures

Existing fixtures in `tests/fixtures/`:

| Fixture | Primary failure |
|---|---|
| `environment-failure.log` | Environment - failure |
| `electron-log-system-check.log` | Environment - failure |
| `structured-module-check.log` | Process blocklist - failure |
| `failed-to-close-apps.log` | failed to close |
| `clock-failure.log` | Clock accuracy - failure |
| `memory-screens-power.log` | Multiple hardware failures |
| `real-auckland-1781002029.log` | Real IIB log sample |

## Log location on exam PCs

`%TEMP%` → `inspera-launcher-XXXXXXXXXX.log` (highest number = newest).

Configured search paths: `data/config.json` → `logDirectories`.
