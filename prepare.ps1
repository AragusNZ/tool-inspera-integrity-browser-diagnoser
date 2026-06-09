#Requires -Version 5.1
<#
.SYNOPSIS
    Prepare the exam PC before launching Inspera Integrity Browser.
.DESCRIPTION
    Closes blocklisted processes, audits environment, and runs pre-flight
    checks. Default is dry-run; use -Apply to actually terminate processes.
.PARAMETER Apply
    Perform actions (kill processes, WSL shutdown). Without this, dry-run only.
.PARAMETER LogPath
    Path to a specific IIB log for blocklist hints. Defaults to newest in %TEMP%.
.PARAMETER InsperaUrl
    URL for network connectivity check.
.PARAMETER Proctored
    Include proctored-exam checks (disk space).
.PARAMETER MaxDisplays
    Maximum allowed displays during IIB checks (default 1).
.EXAMPLE
    .\prepare.ps1
.EXAMPLE
    .\prepare.ps1 -Apply
#>
[CmdletBinding()]
param(
    [switch]$Apply,
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

$result = Invoke-InsperaPrepareToolkit -Apply:$Apply -LogPath $LogPath -InsperaUrl $InsperaUrl `
    -Proctored:$Proctored -MaxDisplays $MaxDisplays
Write-InsperaToolkitResultToConsole -Result $result
exit $result.ExitCode
