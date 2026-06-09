#Requires -Version 5.1
<#
.SYNOPSIS
    Build the Inspera Exam Helper release bundle (exe + lib + data).
.DESCRIPTION
    Compiles Inspera-Toolkit.ps1 to Inspera Exam Helper.exe using ps2exe,
    copies runtime assets into dist/InsperaExamHelper/, and creates a zip.
    Must be run on Windows with Windows PowerShell 5.1+.
.EXAMPLE
    .\build.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -eq 'Core') {
    throw 'Build requires Windows PowerShell 5.1. Run: powershell -NoProfile -File .\build.ps1'
}

$root = $PSScriptRoot
$distDir = Join-Path $root 'dist\InsperaExamHelper'
$exePath = Join-Path $distDir 'Inspera Exam Helper.exe'
$inputScript = Join-Path $root 'Inspera-Toolkit.ps1'
$zipPath = Join-Path $root 'dist\InsperaExamHelper.zip'

try {
    Import-Module ps2exe -ErrorAction Stop
} catch {
    Write-Host 'ps2exe not found — installing for CurrentUser (requires network)...' -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
    Import-Module ps2exe -ErrorAction Stop
}

if (-not (Test-Path $inputScript)) {
    throw "Entry script not found: $inputScript"
}

Write-Host 'Building Inspera Exam Helper...' -ForegroundColor Cyan

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
    -company 'Inspera Toolkit'

Write-Host "  Compiled: $exePath" -ForegroundColor DarkGray

Copy-Item -Path (Join-Path $root 'lib') -Destination (Join-Path $distDir 'lib') -Recurse -Force
Copy-Item -Path (Join-Path $root 'data') -Destination (Join-Path $distDir 'data') -Recurse -Force
Write-Host '  Copied lib/ and data/' -ForegroundColor DarkGray

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

IT staff can edit data\config.json to change log search paths.
'@ | Set-Content -Path $readmeTxt -Encoding UTF8

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Compress-Archive -Path $distDir -DestinationPath $zipPath -Force
Write-Host "  Created: $zipPath" -ForegroundColor DarkGray

Write-Host ''
Write-Host 'Build complete.' -ForegroundColor Green
Write-Host "  Folder: $distDir"
Write-Host "  Zip:    $zipPath"
