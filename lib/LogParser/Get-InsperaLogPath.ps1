function Get-InsperaLogPath {
    param(
        [string]$LogPath
    )

    if ($LogPath) {
        if (-not (Test-Path $LogPath)) {
            return $null
        }
        return (Resolve-Path $LogPath).Path
    }

    $searchDirs = Get-InsperaLogSearchDirectories
    $logs = Get-InsperaLogFiles -Directories $searchDirs

    if (-not $logs -or $logs.Count -eq 0) {
        return $null
    }

    $latest = $logs | Sort-Object {
        if ($_.BaseName -match 'inspera-launcher-(\d+)$') {
            [long]$Matches[1]
        } else {
            $_.LastWriteTime.Ticks
        }
    } -Descending | Select-Object -First 1

    return $latest.FullName
}
