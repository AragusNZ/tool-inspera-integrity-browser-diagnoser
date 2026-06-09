#Requires -Version 5.1
<#
.SYNOPSIS
    Build the Inspera Exam Helper release bundle (exe + lib + data).
.DESCRIPTION
    Compiles Inspera-Toolkit.ps1 to Inspera Exam Helper.exe using ps2exe,
    copies runtime assets into dist/InsperaExamHelper/, and creates a zip.
    Must be run on Windows with Windows PowerShell 5.1+.

    If execution policy blocks this script, use build.cmd instead:
      .\build.cmd
.EXAMPLE
    .\build.cmd
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -eq 'Core') {
    throw 'Build requires Windows PowerShell 5.1. Run: powershell -NoProfile -File .\build.ps1'
}

if (-not $IsWindows -and $env:OS -notmatch 'Windows') {
    throw 'Build must be run on Windows.'
}

$root = $PSScriptRoot
$requirements = Import-PowerShellDataFile (Join-Path $root 'requirements.psd1')
$ps2exeVersion = $requirements.ps2exe
$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
$distName = 'InsperaExamHelper'
$distDir = Join-Path $root "dist\$distName"
$exePath = Join-Path $distDir 'Inspera Exam Helper.exe'
$inputScript = Join-Path $root 'Inspera-Toolkit.ps1'
$zipPath = Join-Path $root "dist\${distName}-${version}.zip"
$checksumPath = "$zipPath.sha256"

$studentCmdFiles = @(
    'Prepare My PC.cmd',
    'Check If Ready.cmd',
    'Why Did Inspera Fail.cmd',
    'Start Inspera Toolkit.cmd'
)
$studentScriptFiles = @(
    'diagnose.ps1',
    'prepare.ps1',
    'inspera-preflight.ps1',
    'Inspera-Toolkit.ps1'
)

function Install-InsperaPsModule {
    param(
        [string]$Name,
        [string]$RequiredVersion
    )

    try {
        Import-Module $Name -RequiredVersion $RequiredVersion -ErrorAction Stop
    } catch {
        Write-Host "$Name $RequiredVersion not found - installing for CurrentUser (requires network)..." -ForegroundColor Yellow
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        Install-Module $Name -RequiredVersion $RequiredVersion -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Import-Module $Name -RequiredVersion $RequiredVersion -ErrorAction Stop
    }
}

Install-InsperaPsModule -Name 'ps2exe' -RequiredVersion $ps2exeVersion

if (-not (Test-Path $inputScript)) {
    throw "Entry script not found: $inputScript"
}

Write-Host "Building Inspera Exam Helper v$version..." -ForegroundColor Cyan

if (Test-Path $distDir) {
    Remove-Item -Path $distDir -Recurse -Force
}
New-Item -Path $distDir -ItemType Directory -Force | Out-Null

Invoke-ps2exe `
    -inputFile $inputScript `
    -outputFile $exePath `
    -STA `
    -noConsole `
    -winFormsDPIAware `
    -title 'Inspera Exam Helper' `
    -description 'Prepare your PC and understand Inspera failures' `
    -product 'Inspera Exam Helper' `
    -company 'Inspera Toolkit' `
    -version $version

Write-Host "  Compiled: $exePath" -ForegroundColor DarkGray

Copy-Item -Path (Join-Path $root 'lib') -Destination (Join-Path $distDir 'lib') -Recurse -Force
Copy-Item -Path (Join-Path $root 'data') -Destination (Join-Path $distDir 'data') -Recurse -Force
Write-Host '  Copied lib/ and data/' -ForegroundColor DarkGray

foreach ($cmdFile in $studentCmdFiles) {
    $source = Join-Path $root $cmdFile
    if (-not (Test-Path $source)) {
        throw "Student shortcut not found: $source"
    }
    Copy-Item -Path $source -Destination (Join-Path $distDir $cmdFile) -Force
}
foreach ($scriptFile in $studentScriptFiles) {
    $source = Join-Path $root $scriptFile
    if (-not (Test-Path $source)) {
        throw "Student script not found: $source"
    }
    Copy-Item -Path $source -Destination (Join-Path $distDir $scriptFile) -Force
}
Write-Host '  Copied student .cmd shortcuts and entry scripts' -ForegroundColor DarkGray

$gitSha = 'unknown'
try {
    $gitSha = (git -C $root rev-parse --short HEAD 2>$null)
    if (-not $gitSha) { $gitSha = 'unknown' }
} catch {
    $gitSha = 'unknown'
}

$buildInfo = @(
    "Inspera Exam Helper $version"
    "Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')"
    "Git: $gitSha"
)
$buildInfo | Set-Content -Path (Join-Path $distDir 'BUILD.txt') -Encoding UTF8

$readmeTxt = Join-Path $distDir 'README.txt'
@'
Inspera Exam Helper
===================

Double-click "Inspera Exam Helper.exe" to open the graphical helper.

Recommended order:
  1. Prepare my PC for the exam
  2. Am I ready?
  3. Launch Inspera Integrity Browser
  4. If it fails: Why did Inspera fail?

If some apps cannot be closed, right-click the exe and choose Run as administrator,
then run Prepare again.

Fallback shortcuts (if antivirus blocks the exe):
  - Start Inspera Toolkit.cmd
  - Prepare My PC.cmd
  - Check If Ready.cmd
  - Why Did Inspera Fail.cmd

IT staff can edit data\config.json to change log search paths.
See the full README in the source repository for advanced options.
'@ | Set-Content -Path $readmeTxt -Encoding UTF8

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
if (Test-Path $checksumPath) {
    Remove-Item -Path $checksumPath -Force
}
Compress-Archive -Path $distDir -DestinationPath $zipPath -Force
$hash = Get-FileHash -Path $zipPath -Algorithm SHA256
"$($hash.Hash)  $(Split-Path -Leaf $zipPath)" | Set-Content -Path $checksumPath -Encoding ASCII
Write-Host "  Created: $zipPath" -ForegroundColor DarkGray
Write-Host "  Checksum: $checksumPath" -ForegroundColor DarkGray

Write-Host '  Running dist smoke check...' -ForegroundColor DarkGray
$fixture = Join-Path $root 'tests\fixtures\environment-failure.log'
$InsperaToolkitRoot = $distDir
. (Join-Path $distDir 'lib\Bootstrap-InsperaToolkit.ps1')
$smoke = Invoke-InsperaDiagnoseToolkit -LogPath $fixture
if ($smoke.ExitCode -ne 1) {
    throw "Dist smoke check failed: expected exit code 1, got $($smoke.ExitCode)"
}

Write-Host ''
Write-Host 'Build complete.' -ForegroundColor Green
Write-Host "  Folder: $distDir"
Write-Host "  Zip:    $zipPath"
Write-Host "  SHA256: $checksumPath"
