# Auto-loader for SystemChecks functions. Dot-source: . (Join-Path $libDir 'SystemChecks.ps1')
$ErrorActionPreference = 'Stop'
if (-not $script:InsperaProjectRoot) {
    $script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$InsperaLibModuleRoot = $PSScriptRoot
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'SystemChecks') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
