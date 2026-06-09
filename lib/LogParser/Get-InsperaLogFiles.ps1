function Get-InsperaLogFiles {
    param([string[]]$Directories)

    $allLogs = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    foreach ($dir in $Directories) {
        if (-not (Test-Path $dir)) {
            continue
        }
        $logs = Get-ChildItem -Path $dir -Filter 'inspera-launcher-*.log' -ErrorAction SilentlyContinue
        foreach ($log in $logs) {
            [void]$allLogs.Add($log)
        }
    }

    return @($allLogs)
}
