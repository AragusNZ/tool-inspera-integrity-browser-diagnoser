#Requires -Version 5.1
<#
.SYNOPSIS
    Run the Inspera toolkit Pester test suite.
.PARAMETER Filter
    Run only tests matching this name (Pester -Filter).
.PARAMETER Path
    Run a single test file or directory (default: .\tests).
.EXAMPLE
    .\test.ps1
.EXAMPLE
    .\test.ps1 -Filter 'Parses real IIB Go launcher log'
.EXAMPLE
    .\test.ps1 -Path .\tests\LogParser.Tests.ps1
#>
[CmdletBinding()]
param(
    [string]$Filter,
    [string]$Path
)

$ErrorActionPreference = 'Stop'

# Prevent Prepare -Apply from running wsl --shutdown during Pester (crashes WSL dev hosts).
$env:INSPERA_TEST_MODE = '1'

$requirements = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'requirements.psd1')
$pesterVersion = $requirements.Pester

try {
    Import-Module Pester -RequiredVersion $pesterVersion -ErrorAction Stop
} catch {
    Write-Host "Pester $pesterVersion not found - installing for CurrentUser (requires network)..." -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Host '  Installing NuGet package provider...' -ForegroundColor DarkGray
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
        Write-Host '  Trusting PSGallery...' -ForegroundColor DarkGray
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Write-Host "  Downloading Pester $pesterVersion from PSGallery (may take a minute)..." -ForegroundColor DarkGray
    Install-Module Pester -RequiredVersion $pesterVersion -Force -Scope CurrentUser -AllowClobber -Repository PSGallery -SkipPublisherCheck
    Write-Host '  Pester installed.' -ForegroundColor DarkGray
    Import-Module Pester -RequiredVersion $pesterVersion -ErrorAction Stop
}

$testPath = if ($Path) {
    $resolved = Join-Path $PSScriptRoot $Path
    if (-not (Test-Path $resolved)) {
        throw "Test path not found: $resolved"
    }
    $resolved
} else {
    Join-Path $PSScriptRoot 'tests'
}

$pesterParams = @{
    Path     = $testPath
    Output   = 'Detailed'
    PassThru = $true
}

if ($Filter) {
    $pesterParams['Filter'] = $Filter
}

$result = Invoke-Pester @pesterParams

Write-Host ''
Write-Host "Tests: $($result.TotalCount)  Passed: $($result.PassedCount)  Failed: $($result.FailedCount)  Skipped: $($result.SkippedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Red' })

exit [int]($result.FailedCount -gt 0)
