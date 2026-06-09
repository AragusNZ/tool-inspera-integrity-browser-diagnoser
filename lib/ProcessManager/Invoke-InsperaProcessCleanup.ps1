function Invoke-InsperaProcessCleanup {
    param(
        [string]$LogPath,
        [switch]$Apply
    )

    $matches = Get-InsperaRunningBlocklistMatches -LogPath $LogPath
    $results = [System.Collections.Generic.List[object]]::new()

    # Never kill ourselves or PowerShell hosting the script
    $selfPid = $PID
    $protected = @('powershell', 'pwsh', 'Inspera', 'inspera', 'csrss', 'winlogon', 'explorer')

    foreach ($match in $matches) {
        if ($match.Id -eq $selfPid) { continue }
        if ($protected | Where-Object { $match.ProcessName -like "$_*" }) { continue }

        $results.Add((Stop-InsperaProcess -ProcessId $match.Id -ProcessName $match.ProcessName -Apply:$Apply))
    }

    return @($results)
}
