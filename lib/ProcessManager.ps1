# Auto-loader for ProcessManager functions. Dot-source: . (Join-Path $libDir 'ProcessManager.ps1')
$ErrorActionPreference = 'Stop'
if (-not $script:InsperaProjectRoot) {
    $script:InsperaProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$InsperaLibModuleRoot = $PSScriptRoot
if (-not (Get-Command Get-InsperaLogPath -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'LogParser.ps1')
}
Get-ChildItem -Path (Join-Path $InsperaLibModuleRoot 'ProcessManager') -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }
