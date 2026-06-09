function Get-InsperaDefaultBlocklist {
    $path = Get-InsperaDataPath 'default-blocklist.json'
    if (-not (Test-Path $path)) {
        throw "Blocklist not found: $path"
    }
    return Get-Content -Path $path -Raw -Encoding UTF8 | ConvertFrom-Json
}
