#Requires -Version 5.1
<#
.SYNOPSIS
    Read-only audit of exam PC readiness and last IIB failure.
.DESCRIPTION
    Combines log diagnosis with environment audit and system checks
    without killing any processes. Use days before an exam or after
    a mid-session failure.
.PARAMETER LogPath
    Path to a specific IIB log file.
.PARAMETER InsperaUrl
    URL for network connectivity check.
.PARAMETER Proctored
    Include proctored-exam checks.
.PARAMETER MaxDisplays
    Maximum allowed displays during IIB checks (default 1).
.EXAMPLE
    .\inspera-preflight.ps1
#>
[CmdletBinding()]
param(
    [string]$LogPath,
    [string]$InsperaUrl,
    [switch]$Proctored,
    [int]$MaxDisplays = 1
)

$ErrorActionPreference = 'Stop'
$libDir = Join-Path $PSScriptRoot 'lib'
. (Join-Path $libDir 'Common.ps1')
. (Join-Path $libDir 'LogParser.ps1')
. (Join-Path $libDir 'ProcessManager.ps1')
. (Join-Path $libDir 'SystemChecks.ps1')
. (Join-Path $libDir 'ToolkitActions.ps1')

$result = Invoke-InsperaPreflightToolkit -LogPath $LogPath -InsperaUrl $InsperaUrl `
    -Proctored:$Proctored -MaxDisplays $MaxDisplays
Write-InsperaToolkitResultToConsole -Result $result
exit $result.ExitCode
