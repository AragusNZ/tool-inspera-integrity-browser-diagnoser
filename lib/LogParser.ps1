# Auto-loader for LogParser functions. Dot-source: . (Join-Path $libDir 'LogParser.ps1')
$ErrorActionPreference = 'Stop'
if (-not $script:InsperaProjectRoot) {
    $script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$InsperaLibModuleRoot = $PSScriptRoot
if (-not (Get-Command Get-InsperaDataPath -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Common.ps1')
}
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'LogParser') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
