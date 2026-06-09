function Get-InsperaRunningBlocklistMatches {
    param([string]$LogPath)

    $entries = Get-InsperaBlocklistEntries -LogPath $LogPath
    $default = Get-InsperaDefaultBlocklist
    $running = Get-Process -ErrorAction SilentlyContinue
    $matches = [System.Collections.Generic.List[object]]::new()

    foreach ($proc in $running) {
        $procName = $proc.ProcessName
        $procExe = "$procName.exe"

        foreach ($entry in $entries) {
            if ($entry.Name -ieq $procExe -or $entry.Name -ieq $procName) {
                $matches.Add([PSCustomObject]@{
                    Id = $proc.Id
                    ProcessName = $proc.ProcessName
                    Category = $entry.Category
                    Source = $entry.Source
                })
                break
            }
        }

        foreach ($pattern in $default.processNamePatterns) {
            if ($procName -like "*$($pattern.pattern)*" -or $procExe -like "*$($pattern.pattern)*") {
                if (-not ($matches | Where-Object { $_.Id -eq $proc.Id })) {
                    $matches.Add([PSCustomObject]@{
                        Id = $proc.Id
                        ProcessName = $proc.ProcessName
                        Category = $pattern.category
                        Source = 'pattern'
                    })
                }
            }
        }
    }

    return @($matches)
}
