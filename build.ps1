# Builds dist\InsperaExamHelper\ (onedir), then dist\InsperaExamHelper-<version>-setup.exe,
# dist\InsperaExamHelper-<version>.zip and dist\SHA256SUMS.txt.
# Needs uv on the Windows PATH; it fetches the Python that .python-version names. From WSL run ./build.sh -
# it runs this script with Windows uv over \\wsl.localhost.
# The PyInstaller work dir lives under %LOCALAPPDATA%\inspera-exam-helper, and so does the venv when the repo
# is a UNC path: a venv over \\wsl.localhost is unusably slow.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$work = Join-Path $env:LOCALAPPDATA 'inspera-exam-helper'
New-Item -ItemType Directory -Force $work | Out-Null  # absent on a fresh machine, e.g. the release runner
if ($PSScriptRoot.StartsWith('\\')) { $env:UV_PROJECT_ENVIRONMENT = "$work\venv" }
uv sync --locked
if ($LASTEXITCODE -ne 0) { throw 'uv sync failed' }

$version = (Get-Content "$PSScriptRoot\VERSION" -Raw).Trim()
$name = 'InsperaExamHelper'

# Without a version resource the exe has no publisher string at all, so Windows calls it unknown and
# SmartScreen has nothing to name. Derived from VERSION - never hardcode it. Win32 wants four fields.
$v4 = (($version.Split('.') + @('0', '0', '0', '0'))[0..3]) -join ', '
$verInfo = "$work\version_info.txt"
@"
VSVersionInfo(
  ffi=FixedFileInfo(filevers=($v4), prodvers=($v4), mask=0x3f, flags=0x0,
                    OS=0x40004, fileType=0x1, subtype=0x0, date=(0, 0)),
  kids=[
    StringFileInfo([StringTable('040904B0', [
      StringStruct('CompanyName', 'AragusNZ'),
      StringStruct('FileDescription', 'Inspera Exam Helper'),
      StringStruct('FileVersion', '$version.0'),
      StringStruct('InternalName', '$name'),
      StringStruct('LegalCopyright', 'Copyright (c) AragusNZ'),
      StringStruct('OriginalFilename', '$name.exe'),
      StringStruct('ProductName', 'Inspera Exam Helper'),
      StringStruct('ProductVersion', '$version.0')])]),
    VarFileInfo([VarStruct('Translation', [1033, 1200])])
  ]
)
"@ | Set-Content $verInfo -Encoding ascii

# onedir, not onefile: a onefile bootloader unpacks a Python runtime into %TEMP% and runs it, which is
# the PyInstaller behaviour antivirus flags hardest. --noupx drops the other heuristic.
# Asset paths are absolute: a relative --add-data/--icon resolves against --specpath, which is outside the repo.
uv run --no-sync python -m PyInstaller --noconfirm --clean --onedir --noupx --windowed --name $name `
    --icon "$PSScriptRoot\inspera_exam_helper\assets\icon.ico" --version-file "$verInfo" `
    --add-data "$PSScriptRoot\inspera_exam_helper\assets;inspera_exam_helper\assets" `
    --add-data "$PSScriptRoot\inspera_exam_helper\data;inspera_exam_helper\data" `
    --add-data "$PSScriptRoot\VERSION;." `
    --workpath "$work\build" --specpath "$work" inspera_exam_helper\__main__.py
if ($LASTEXITCODE -ne 0) { throw 'PyInstaller failed' }

# The frozen exe must find its bundled data, icon and VERSION; a wrong --add-data shows up here, not on a
# student's PC. A windowed exe does not block the console, hence Start-Process -Wait.
$smoke = Start-Process "dist\$name\$name.exe" -ArgumentList '--check' -Wait -PassThru
if ($smoke.ExitCode -ne 0) { throw "Smoke check failed: dist\$name\$name.exe --check exited $($smoke.ExitCode)" }


# --onedir already wrote dist\InsperaExamHelper\InsperaExamHelper.exe and its _internal\ beside it.
$stage = "dist\$name"
Copy-Item 'README.md' $stage
Copy-Item 'LICENSE' $stage
# IT edits this copy. The installer only writes it when absent, so an upgrade keeps their edits.
Copy-Item 'inspera_exam_helper\data\config.json' $stage

$setup = "dist\$name-$version-setup.exe"
# winget installs Inno Setup per-user under LOCALAPPDATA; the installer from jrsoftware.org and
# the choco package the release workflow uses both land in Program Files (x86).
$iscc = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { $iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source }
if ($iscc) {
    if (Test-Path $setup) { Remove-Item $setup }
    & $iscc /Qp /DAppVersion=$version "$PSScriptRoot\packaging\inspera-exam-helper.iss"
    if ($LASTEXITCODE -ne 0) { throw 'ISCC failed' }
} else {
    Write-Warning 'Inno Setup 6 not found - skipping the installer. winget install JRSoftware.InnoSetup'
}

$zip = "dist\$name-$version.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path "$stage\*" -DestinationPath $zip

# Written by hand rather than with Set-Content: the PowerShell 5.1 default is UTF-16, and even
# -Encoding ascii still emits CRLF. `sha256sum -c` reads neither.
$sums = @($setup, $zip) | Where-Object { Test-Path $_ } | ForEach-Object {
    (Get-FileHash $_ -Algorithm SHA256).Hash.ToLower() + '  ' + (Split-Path $_ -Leaf)
}
[IO.File]::WriteAllText("$PSScriptRoot\dist\SHA256SUMS.txt", ($sums -join "`n") + "`n")
Write-Host "Built $($sums.Count) artifact(s) in dist\ for $version"
