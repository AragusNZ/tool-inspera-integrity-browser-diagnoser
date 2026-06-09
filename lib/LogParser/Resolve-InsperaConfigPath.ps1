function Resolve-InsperaConfigPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $resolved = $Path.Trim()
    $resolved = $resolved -replace '%USERNAME%', $env:USERNAME
    $resolved = $resolved -replace '%USERPROFILE%', $env:USERPROFILE
    $tempPath = [System.IO.Path]::GetTempPath().TrimEnd('\')
    $resolved = $resolved -replace '%TEMP%', $tempPath
    return $resolved
}
