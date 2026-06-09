# Dot-source at script scope after setting $InsperaToolkitRoot.
if (-not $InsperaToolkitRoot) {
    throw 'Set $InsperaToolkitRoot before dot-sourcing Bootstrap-InsperaToolkit.ps1'
}

$libDir = Join-Path $InsperaToolkitRoot 'lib'
. (Join-Path $libDir 'Common.ps1')
. (Join-Path $libDir 'LogParser.ps1')
. (Join-Path $libDir 'ProcessManager.ps1')
. (Join-Path $libDir 'SystemChecks.ps1')
. (Join-Path $libDir 'ToolkitActions.ps1')
