# Inspera Exam Helper

Windows desktop tool for students sitting exams in Inspera Integrity Browser (IIB). Three buttons: prepare the
PC, check it is ready, and explain why Inspera failed last time.

Nothing leaves your PC. It reads Inspera's own log file on your machine and runs checks locally. The only thing it
asks the internet is whether Inspera's site answers and whether a newer version of this tool is out.

## Install

Download the latest **`InsperaExamHelper-<version>-setup.exe`** from
[Releases](https://github.com/AragusNZ/tool-inspera-integrity-browser-diagnoser/releases) and run it.

- It installs per-user into `%LOCALAPPDATA%\Programs\Inspera Exam Helper` and never asks for admin rights.
- Windows 10 or 11, 64-bit. Nothing else to install.
- Windows will warn about the publisher. That is expected, and [what to do](#windows-security-warnings) is below.
- `InsperaExamHelper-<version>.zip` is the same program as a plain folder, for a machine where installers are
  blocked. Unzip it anywhere and run `InsperaExamHelper.exe`.
- To update: on start it checks GitHub for a newer release and offers to open the download page.
  **Help > Check for Updates** asks any time; untick **Help > Check on Startup** to stop the automatic check.
  Run the new `setup.exe` over the top — it upgrades in place and keeps your settings and IT's `config.json`.
- To remove it: **Settings > Apps > Installed apps > Inspera Exam Helper > Uninstall**.

Verify a download against `SHA256SUMS.txt` from the same release:

```
Get-FileHash .\InsperaExamHelper-<version>-setup.exe -Algorithm SHA256
```

### Windows security warnings

The exe is not code-signed, so SmartScreen shows **Windows protected your PC** the first time. Click **More info**,
then **Run anyway**. If a download is blocked outright, right-click the file > **Properties** > tick **Unblock**, or
in PowerShell: `Unblock-File .\InsperaExamHelper-<version>-setup.exe`.

## What it does

| Button | What happens |
|---|---|
| **Prepare my PC for the exam** | Closes apps Inspera refuses to run beside (Discord, OBS, remote-control tools, ...), shuts down WSL, then runs every readiness check. Asks before closing anything. |
| **Am I ready?** | Read-only: the last Inspera failure if there was one, the environment audit, the readiness checks, and which interfering apps are still running. |
| **Why did Inspera fail?** | Reads the newest `inspera-launcher-*.log`, names the failure in plain words, lists what to try, and re-runs the live checks that relate to it. |
| **Run recommended steps** | Prepare, then a short readiness pass, then the launch checklist. |

Lines are colour-coded: green passed, red failed, amber is a warning worth reading.

## Exam-day checklist

- [ ] Open **Inspera Exam Helper**
- [ ] Click **Prepare my PC for the exam** (confirm when asked)
- [ ] Click **Am I ready?** — all checks should pass
- [ ] Disconnect a second monitor (reconnect after the system checks if allowed)
- [ ] Plug in the charger
- [ ] Close virtual desktops (Win+Tab)
- [ ] Disable VPN unless your institution requires it
- [ ] Launch Inspera Integrity Browser and complete its system checks
- [ ] If it fails: click **Why did Inspera fail?** and follow the steps shown

## Run as administrator

A few protected apps cannot be closed by a normal user. If **Prepare my PC** reports apps it could not close,
right-click **Inspera Exam Helper** in the Start menu, choose **Run as administrator**, and click **Prepare my PC**
again.

## What Inspera Integrity Browser requires

From Inspera's [system requirements](https://support.inspera.com/hc/en-us/articles/35448508218397) (updated
2026-10-21) and [troubleshooting](https://support.inspera.com/hc/en-us/articles/5118836955549) articles. The helper
checks each row it can.

| Requirement | Detail | Check |
|---|---|---|
| Windows | 10 or 11, 64-bit. Windows 7/8.1 unsupported since IIB 1.14.19. ARM only from IIB 2.3.0. S mode blocks install | Windows version |
| CPU | Intel Sandy Bridge (2011) or newer, or AMD with SSE4.2 | CPU SSE4.2 |
| Graphics | OpenGL 2.0 capable driver (the basic display adapter crashes the IIB UI) | Graphics driver |
| Disk | 500 MB free; proctored exams record 75 MB per hour | Disk space |
| Network | 0.15 Mbps up / 0.20 Mbps down; online during install (config file download) | Network connectivity, Connection quality |
| Clock | Synced to `time.google.com` (NTP, UDP/TCP 123) | Clock accuracy |
| Screens | One display during system checks (virtual and remote screens count) | Display count |
| Power | Laptop plugged in when the institution enables the power check | Power state |
| Environment | No virtual machine, no Remote Desktop session, no remote-control or screen-sharing apps | Virtual machine, Remote session, Interfering apps, Virtualization features |
| IIB version | 1.15.4 or newer for security fixes; the old Inspera Exam Portal uninstalled | IIB installation |
| Admin rights | Needed to install IIB and for Strict lockdown exams | Administrator rights (info) |
| Keyboard | Layout on the institution's approved list | Keyboard language |
| Webcam | Working camera for proctored exams; Microsoft LifeCam HD-3000 is known to fail | Webcam (proctored) |

### Failure types explained

System checks: Environment, Process blocklist, Connection quality, Clock accuracy, Number of screens, Power state,
Memory, CPU (SSE4.2), App version, Login configuration, Device check, Keyboard language.

Runtime: Desktop changed, Failed to close applications, iceworm failure, UI runtime errors, IIB already running,
Configuration download failed.

Proctoring: Screen capture, Webcam, File upload.

### Apps it closes

Remote access: TeamViewer, AnyDesk, RustDesk, Parsec, Chrome Remote Desktop, Splashtop, LogMeIn, UltraViewer,
Supremo, VNC. Recording: OBS, ShareX, Camtasia, Bandicam, Loom, Snagit, Greenshot. Overlays: Xbox Game Bar, NVIDIA
Share, RTSS / MSI Afterburner. Chat: Discord, Slack, Teams, Zoom, Skype, Telegram, Signal, WhatsApp, Webex. VMs:
VirtualBox, VMware, Hyper-V (vmconnect), QEMU. Known blockers: AvastBrowser.exe, HP desktopextension.exe.

The helper also closes any app the newest Inspera log says it failed to close.

## For IT

### Configuration

`config.json` sits beside `InsperaExamHelper.exe` (in `%LOCALAPPDATA%\Programs\Inspera Exam Helper` after a
normal install). The installer writes it once and never overwrites it, so your edits survive upgrades.

```json
{
  "logDirectories": ["%TEMP%"],
  "fallbackToUserTemp": true,
  "insperaUrl": "https://www.inspera.com",
  "minimumIibVersion": "1.15.4",
  "approvedKeyboardLanguages": []
}
```

- **logDirectories** — folders to search for `inspera-launcher-*.log`, in order. Placeholders: `%USERNAME%`,
  `%USERPROFILE%`, `%TEMP%`.
- **fallbackToUserTemp** — also search the current user's `%TEMP%`, which is where IIB writes by default.
- **insperaUrl** — URL for the network checks. The tenant recorded in the log (`<institution>.inspera.com`) is used
  automatically when the log has one.
- **minimumIibVersion** — an installed IIB older than this fails the *IIB installation* check.
- **approvedKeyboardLanguages** — BCP-47 tags such as `["en"]` or `["en-NZ", "mi"]`; `"en"` matches every `en-*`
  layout. An empty list keeps the check informational.

A missing or unreadable `config.json` means those defaults.

### Network allowlist

- `time.google.com` UDP/TCP 123 (NTP, used by IIB's clock check and this helper)
- `<tenant>.inspera.com` (login, blocklist download)
- `*.cloudfront.net` (IIB's `connectionCheck.json` probe and content)
- `api.github.com` and `github.com` only for this helper's update check; block them and it simply says it could
  not check

Proxies that intercept TLS commonly cause **Login configuration error**; Inspera's advice is to change networks.

### Where IIB logs live

`%TEMP%` for the signed-in user — `C:\Users\<USER>\AppData\Local\Temp`. Files are named
`inspera-launcher-XXXXXXXXXX.log`; the highest number is the newest session.

### Deployment

The `setup.exe` takes Inno Setup's standard switches: `/VERYSILENT /NORESTART` for SCCM or Intune. It is per-user,
so run it in the user context. Pre-seed `config.json` beside the exe after the first install if your log folders
or keyboard policy differ from the defaults.

Anything the helper writes about itself goes to `%TEMP%\InsperaExamHelper.log` — that is the file to ask for when
it misbehaves.

## Limitations

- Cannot fetch IIB's live server-side blocklist; it uses the built-in list plus names from the log
- The clock and network checks need internet
- Windows only
- `Device check failure` is institution policy — contact your exam provider
- A CPU without SSE4.2 cannot be fixed in software

## References

- [Inspera system requirements: IIB & Resilience Proctoring](https://support.inspera.com/hc/en-us/articles/35448508218397) (updated 2026-10-21)
- [Inspera system errors](https://support.inspera.com/hc/en-us/articles/5118836955549) (updated 2026-06-26)
- [Features/tools not supported within IIB](https://support.inspera.com/hc/en-us/articles/4918910374813) (remote sessions)
- [University of Auckland IIB Troubleshooting Guide](https://www.auckland.ac.nz/assets/students/academic-information/exams-and-final-results/IIB%20Troubleshooting%20Guide.pdf)
- [Leeds Beckett: What do the error messages in Inspera mean?](https://libanswers.leedsbeckett.ac.uk/faq/263699)
- [Inspera log file location](https://support.inspera.com/hc/en-us/articles/360018558518)
- [Inspera proctoring errors](https://support.inspera.com/hc/en-us/articles/4409547578769)

## Licence

MIT, Copyright (c) AragusNZ. Source and issues:
[github.com/AragusNZ/tool-inspera-integrity-browser-diagnoser](https://github.com/AragusNZ/tool-inspera-integrity-browser-diagnoser).
