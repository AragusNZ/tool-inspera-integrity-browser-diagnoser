function Get-InsperaBlocklistEntries {
    param([string]$LogPath)

    $default = Get-InsperaDefaultBlocklist
    $entries = [System.Collections.Generic.List[object]]::new()

    foreach ($proc in $default.processes) {
        $entries.Add([PSCustomObject]@{
            Name = $proc.name
            Category = $proc.category
            Source = 'default'
        })
    }

    $logApps = Get-InsperaBlocklistFromLog -LogPath $LogPath
    foreach ($app in $logApps) {
        $name = if ($app -match '\.(exe|app)$') { $app } else { "$app.exe" }
        if (-not ($entries | Where-Object { $_.Name -ieq $name })) {
            $entries.Add([PSCustomObject]@{
                Name = $name
                Category = 'from-log'
                Source = 'log'
            })
        }
    }

    return @($entries)
}
