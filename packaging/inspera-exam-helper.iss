; Installer for the onedir build. Compiled by build.ps1 with /DAppVersion=<VERSION>.
; Per-user by design: PrivilegesRequired=lowest means no UAC prompt, which is one less trust
; dialog on a build that is not yet code-signed, and the tool needs no machine-wide state.
; AppId is fixed forever - it is what makes the next version upgrade this one in place.

[Setup]
AppId={{E747C11B-4CFD-4D6D-8260-692BAD82A825}
AppName=Inspera Exam Helper
AppVersion={#AppVersion}
AppVerName=Inspera Exam Helper {#AppVersion}
AppPublisher=AragusNZ
VersionInfoVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\Inspera Exam Helper
DefaultGroupName=Inspera Exam Helper
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
; What the README promises: Windows 10 or 11, 64-bit. Inspera Integrity Browser needs the same.
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=InsperaExamHelper-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\inspera_exam_helper\assets\icon.ico
LicenseFile=..\LICENSE
UninstallDisplayIcon={app}\InsperaExamHelper.exe

[InstallDelete]
; An upgrade in place must not keep the previous version's DLLs and .pyd files beside the new ones.
Type: filesandordirs; Name: "{app}\_internal"

[Files]
; The leading backslash anchors the exclude to the top level; the bundled default under _internal still ships.
Source: "..\dist\InsperaExamHelper\*"; Excludes: "\config.json"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
; IT edits config.json beside the exe (log folders, approved keyboard languages). Written once, never overwritten.
Source: "..\dist\InsperaExamHelper\config.json"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall

[Registry]
; QSettings keeps window geometry and the update preference here. Nothing is written at install.
Root: HKCU; Subkey: "Software\inspera-exam-helper"; Flags: uninsdeletekey dontcreatekey

[Icons]

Name: "{group}\Inspera Exam Helper"; Filename: "{app}\InsperaExamHelper.exe"
Name: "{userdesktop}\Inspera Exam Helper"; Filename: "{app}\InsperaExamHelper.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\InsperaExamHelper.exe"; Description: "Launch Inspera Exam Helper"; Flags: nowait postinstall skipifsilent
