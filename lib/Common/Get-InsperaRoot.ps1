function Get-InsperaRoot {
    if ($script:InsperaProjectRoot) {
        return $script:InsperaProjectRoot
    }
    if ($InsperaLibModuleRoot) {
        return (Resolve-Path (Join-Path $InsperaLibModuleRoot '..')).Path
    }
    if ($PSScriptRoot) {
        $libRoot = $PSScriptRoot
        if ($libRoot -match '[\\/]lib[\\/](Common|LogParser|ProcessManager|SystemChecks|ToolkitActions|ToolkitGui)$') {
            return Convert-InsperaCanonicalPath (Resolve-Path (Join-Path $libRoot '..\..')).Path
        }
        if ($libRoot -match '[\\/]lib$') {
            return Convert-InsperaCanonicalPath (Resolve-Path (Join-Path $libRoot '..')).Path
        }
    }
    return Get-InsperaAppRoot
}
