# Auto-loader for ToolkitActions functions. Dot-source: . (Join-Path $libDir 'ToolkitActions.ps1')
$ErrorActionPreference = 'Stop'
if (-not $script:InsperaProjectRoot) {
    $script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$InsperaLibModuleRoot = $PSScriptRoot
if (-not (Get-Command New-InsperaToolkitSection -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Common.ps1')
}
if (-not (Get-Command Parse-InsperaLog -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'LogParser.ps1')
}
if (-not (Get-Command Get-InsperaRunningBlocklistMatches -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ProcessManager.ps1')
}
if (-not (Get-Command Invoke-InsperaSystemChecks -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'SystemChecks.ps1')
}
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'ToolkitActions') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
