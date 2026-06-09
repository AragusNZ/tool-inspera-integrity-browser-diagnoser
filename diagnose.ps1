#Requires -Version 5.1
<#
.SYNOPSIS
    Explain why Inspera Integrity Browser last failed.
.DESCRIPTION
    Parses the newest inspera-launcher-*.log in %TEMP% and maps failures
    to human-readable causes and fixes. Also reports currently running
    blocklisted processes and runs live checks relevant to the failure.
.PARAMETER LogPath
    Path to a specific log file instead of auto-discovery.
.PARAMETER VerboseReport
    Show full failure timeline from the log.
.PARAMETER InsperaUrl
    URL for network checks when failure is connection-related.
.EXAMPLE
    .\diagnose.ps1
.EXAMPLE
    .\diagnose.ps1 -LogPath C:\Users\Me\AppData\Local\Temp\inspera-launcher-123.log -VerboseReport
#>
[CmdletBinding()]
param(
    [string]$LogPath,
    [switch]$VerboseReport,
    [string]$InsperaUrl
)

$ErrorActionPreference = 'Stop'
$InsperaToolkitRoot = $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib\Bootstrap-InsperaToolkit.ps1')

$result = Invoke-InsperaDiagnoseToolkit -LogPath $LogPath -InsperaUrl $InsperaUrl -VerboseReport:$VerboseReport
Write-InsperaToolkitResultToConsole -Result $result
exit $result.ExitCode
