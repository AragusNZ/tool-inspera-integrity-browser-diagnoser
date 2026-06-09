# Auto-loader for Common functions. Dot-source: . (Join-Path $libDir 'Common.ps1')
$ErrorActionPreference = 'Stop'
$InsperaLibModuleRoot = $PSScriptRoot
$script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'Common') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
