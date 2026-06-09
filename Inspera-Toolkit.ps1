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
$libDir = Join-Path $PSScriptRoot 'lib'
. (Join-Path $libDir 'ToolkitGui.ps1')

Show-InsperaToolkitGui -RootPath $PSScriptRoot
