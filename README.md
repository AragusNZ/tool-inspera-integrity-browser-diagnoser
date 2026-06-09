# Inspera Integrity Browser Diagnostic & Prep Toolkit

Portable Windows toolkit for Inspera Integrity Browser (IIB). Copy this folder to any exam PC (USB, zip, or git clone) - no installer required.

## What it does

1. **Inspera Exam Helper (GUI)** - Simple window with buttons to prepare your PC, check readiness, and explain failures
2. **`diagnose.ps1`** - Explains why IIB last failed by parsing `inspera-launcher-*.log`
3. **`prepare.ps1`** - Closes interfering apps and runs pre-flight checks
4. **`inspera-preflight.ps1`** - Read-only audit (no process killing)

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built into Windows)
- No Python, Node, or other dependencies

## Quick start (exam PC)

1. Copy the `inspera` folder to the exam PC (e.g. `D:\inspera`)
2. Double-click **`Start Inspera Toolkit.cmd`**
3. Use the buttons in the window:

| Button | What it does |
|--------|----------------|
| **Prepare my PC for the exam** | Closes interfering apps and runs system checks |
| **Am I ready?** | Read-only check - no apps are closed |
| **Why did Inspera fail?** | Explains the last failure and what to try |
| **Run recommended steps** | Prepare, then check readiness, then show a checklist |

4. Launch Inspera Integrity Browser and take your exam
5. If it fails again, click **Why did Inspera fail?**

### Friendly shortcuts (no GUI)

| File | Purpose |
|------|---------|
| `Start Inspera Toolkit.cmd` | Opens the graphical helper |
| `Prepare My PC.cmd` | Closes interfering apps (always applies changes) |
| `Check If Ready.cmd` | Read-only readiness audit |
| `Why Did Inspera Fail.cmd` | Diagnose last failure |

## Exam-day checklist

- [ ] Copy `inspera` folder to exam PC
- [ ] Double-click **Start Inspera Toolkit.cmd**
- [ ] Click **Prepare my PC for the exam** (confirm when asked)
- [ ] Click **Am I ready?** - all checks should pass
- [ ] Disconnect secondary monitor (reconnect after checks if allowed)
- [ ] Plug in charger if IIB requires it
- [ ] Close virtual desktops (Win+Tab)
- [ ] Disable VPN unless required by your institution
- [ ] Launch IIB and complete system checks
- [ ] If failure: click **Why did Inspera fail?** and follow the steps shown

## Run as Administrator

Some protected processes cannot be killed as a normal user. If **Prepare my PC** reports apps that could not be closed:

1. Right-click **Start Inspera Toolkit.cmd** (or **Prepare My PC.cmd**)
2. Choose **Run as administrator**
3. Click **Prepare my PC for the exam** again

## Where IIB logs live

| OS | Default location |
|----|------------------|
| Windows | `C:\Users\<USER>\AppData\Local\Temp` (same as `%TEMP%` for that user) |

Log files are named `inspera-launcher-XXXXXXXXXX.log` (highest number = newest).

### Configuring log search paths

Edit [`data/config.json`](data/config.json) on the exam PC:

```json
{
  "logDirectories": [
    "C:\\Users\\tcase\\AppData\\Local\\Temp"
  ],
  "fallbackToUserTemp": true,
  "insperaUrl": "https://www.inspera.com"
}
```

- **logDirectories** - folders to search, in order
- **fallbackToUserTemp** - also search the current user's `%TEMP%`
- **insperaUrl** - default URL for network checks; tenant from the log is used automatically when available
- Path placeholders: `%USERNAME%`, `%USERPROFILE%`, `%TEMP%`

Open quickly: Win+S, type `%temp%`, look for `inspera-launcher-XXXXXXXXXX.log`.

## Failure types covered

System checks: Environment, Process blocklist, Connection quality, Clock accuracy, Number of screens, Power state, Memory, CPU (SSE4.2), App version, Login configuration, Device check, Keyboard language.

Runtime: Desktop changed, Failed to close applications, iceworm failure, UI runtime errors.

Proctoring: Screen capture, Webcam, File upload.

See `lib/ErrorCatalog.json` for full mapping to causes and fixes.

## Blocklisted processes (default)

Remote access: TeamViewer, AnyDesk, RustDesk, Parsec  
Recording: OBS, ShareX, Camtasia, Bandicam  
Chat: Discord, Slack, Teams, Zoom, Skype, Telegram  
VMs: VirtualBox, VMware  
Known blockers: AvastBrowser.exe  

Full list in `data/default-blocklist.json`. The toolkit also extracts app names from the newest IIB log when available.

## Advanced / IT support

PowerShell scripts remain available for scripting and support staff.

### Library layout

Each module under `lib/` is split into one function per file:

```
lib/
  Common.ps1              # loader (dot-source this)
  Common/                 # Get-InsperaRoot.ps1, Write-InsperaPass.ps1, ...
  LogParser.ps1
  LogParser/
  ProcessManager.ps1
  ProcessManager/
  SystemChecks.ps1
  SystemChecks/
  ToolkitActions.ps1
  ToolkitActions/
  ToolkitGui.ps1
  ToolkitGui/
```

Entry scripts still use `. (Join-Path $libDir 'Common.ps1')` etc. Loaders pull in all functions from the matching subfolder automatically.

| Script | Purpose |
|--------|---------|
| `Inspera-Toolkit.ps1` | Graphical launcher |
| `diagnose.ps1` / `diagnose.cmd` | Parse latest IIB log, show failure reason and live checks |
| `prepare.ps1` / `prepare.cmd` | Close blocklisted apps, environment audit, system checks |
| `inspera-preflight.ps1` / `preflight.cmd` | Read-only audit |

### Script options

**diagnose.ps1**
- `-LogPath <path>` - Use a specific log file
- `-VerboseReport` - Show full failure timeline
- `-InsperaUrl <url>` - Override network check target (config and log tenant used by default)

**prepare.ps1**
- `-Apply` - Actually kill processes (default is dry-run)
- `-LogPath <path>` - Use log for blocklist hints
- `-InsperaUrl <url>` - Override network check target
- `-Proctored` - Include disk-space check for proctored exams
- `-MaxDisplays 1` - Warn if more displays connected

**inspera-preflight.ps1** - same options as above (read-only, no `-Apply`)

### Execution policy

If PowerShell blocks scripts, use the **`.cmd` launchers** (they bypass policy automatically), or:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\prepare.ps1 -Apply
```

## Testing

Run the full Pester suite (parser, blocklist, system checks, entry-script smoke tests):

**WSL dev (runs via Windows PowerShell):**

```bash
./test.sh
```

**Windows:**

```powershell
.\test.ps1
# or: test.cmd
```

`test.ps1` installs Pester 5.x automatically on first run if it is not already available.

## Log parser and fixtures

No public IIB log samples exist online. The parser is built from:

- Official Inspera check names ([login process](https://support.inspera.com/hc/en-us/articles/360056495731), [system errors](https://support.inspera.com/hc/en-us/articles/5118836955549))
- User-facing error text ([Leeds Beckett FAQ](https://libanswers.leedsbeckett.ac.uk/faq/263699))
- Electron-log and structured module formats (synthesized in `tests/fixtures/`)

Supported log line formats:

- **IIB Go launcher (real format):** `2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3`
- **iceworm component:** `iceworm: ... connectionCheck.json`, `iceworm exited: exit status 1`
- **UI crashes:** `Fyne error: GLFW poll event error: ...`
- `[2026-03-15 09:12:34.123] [error] Environment - failure` (electron-log)
- `2026-03-15 09:12:01.005 [01] - ERROR: [SystemCheck] Process blocklist - failure` (structured)
- `{"level":"error","message":"Clock accuracy - failure"}` (JSON lines)
- Official check results: `Environment - success`, `Check "Environment" failed`

A real example log is in [`.example/inspera-launcher-1781002029.log`](.example/inspera-launcher-1781002029.log) (also copied to `tests/fixtures/`).

## Calibrating with your log

If diagnosis reports "No clear failure found", copy your real log from the exam PC:

1. Win+S → `%temp%` → copy newest `inspera-launcher-*.log`
2. Place in `tests/fixtures/your-failure.log`
3. Run `.\diagnose.ps1 -LogPath .\tests\fixtures\your-failure.log -VerboseReport`
4. Share the log to improve parser patterns

## Limitations

- Cannot fetch IIB's live server-side blocklist (uses default + log-extracted names)
- Some checks need internet (NTP, HTTPS)
- Mac not supported in this version
- `Device check failure` is institution policy - contact your exam provider
- CPU without SSE4.2 cannot be fixed in software

## References

- [Inspera system errors](https://support.inspera.com/hc/en-us/articles/5118836955549)
- [Inspera log file location](https://support.inspera.com/hc/en-us/articles/360018558518)
- [Inspera proctoring errors](https://support.inspera.com/hc/en-us/articles/4409547578769)
