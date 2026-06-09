# Auto-loader for ToolkitGui functions. Dot-source: . (Join-Path $libDir 'ToolkitGui.ps1')
$ErrorActionPreference = 'Stop'
if (-not $script:InsperaProjectRoot) {
    $script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$InsperaLibModuleRoot = $PSScriptRoot
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'ToolkitGui') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
