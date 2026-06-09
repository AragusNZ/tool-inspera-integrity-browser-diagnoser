function Import-InsperaModule {
    param([string]$Name)
    $path = Get-InsperaLibPath "$Name.ps1"
    if (-not (Test-Path $path)) {
        throw "Module not found: $path"
    }
    . $path
}
