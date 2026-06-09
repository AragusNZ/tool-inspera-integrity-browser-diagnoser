function Get-InsperaErrorCatalog {
    $catalogPath = Get-InsperaLibPath 'ErrorCatalog.json'
    if (-not (Test-Path $catalogPath)) {
        return @{}
    }
    $raw = Get-Content -Path $catalogPath -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json)
}
