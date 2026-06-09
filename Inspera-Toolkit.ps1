#Requires -Version 5.1
<#
.SYNOPSIS
    Graphical launcher for the Inspera exam preparation toolkit.
.DESCRIPTION
    Opens a simple window with buttons for preparing the PC,
    checking readiness, and diagnosing Inspera failures.
.EXAMPLE
    .\Inspera-Toolkit.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Allow dot-sourcing lib/*.ps1 when launched as a compiled exe (execution policy is otherwise Restricted).
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null

# Bootstrap app root before module loaders run ($PSScriptRoot is empty in ps2exe builds).
if ($PSScriptRoot) {
    $bootstrapRoot = $PSScriptRoot
} else {
    $invoked = [Environment]::GetCommandLineArgs()[0]
    $bootstrapRoot = Split-Path -Parent (Convert-Path -LiteralPath $invoked)
}

$commonDir = Join-Path (Join-Path $bootstrapRoot 'lib') 'Common'
. (Join-Path $commonDir '00-State.ps1')
. (Join-Path $commonDir 'Convert-InsperaCanonicalPath.ps1')
. (Join-Path $commonDir 'Get-InsperaAppRoot.ps1')

$root = Get-InsperaAppRoot
$libDir = Join-Path $root 'lib'
. (Join-Path $libDir 'Common.ps1')
. (Join-Path $libDir 'ToolkitGui.ps1')

Show-InsperaToolkitGui -RootPath $root
