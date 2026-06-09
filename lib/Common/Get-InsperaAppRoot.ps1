function Get-InsperaAppRoot {
    param(
        [string]$InvokedPath
    )

    if ($null -ne $script:InsperaAppRoot -and -not $PSBoundParameters.ContainsKey('InvokedPath')) {
        return $script:InsperaAppRoot
    }
    if ($InvokedPath) {
        $root = Split-Path -Parent (Convert-Path -LiteralPath $InvokedPath)
    } elseif ($PSScriptRoot) {
        if ($PSScriptRoot -match '[\\/]lib[\\/]Common$') {
            $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        } else {
            $root = $PSScriptRoot
        }
    } else {
        $invoked = [Environment]::GetCommandLineArgs()[0]
        $root = Split-Path -Parent (Convert-Path -LiteralPath $invoked)
    }
    $resolved = (Resolve-Path $root).Path
    $script:InsperaAppRoot = Convert-InsperaCanonicalPath $resolved
    return $script:InsperaAppRoot
}
