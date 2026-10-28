function Test-InsperaIibRunning {
    # A stuck inspera-launcher.exe produces "Inspera Integrity Browser already running" on next launch.
    $result = @{
        Name = 'Inspera not already running'
        Passed = $true
        Message = 'Inspera is not running in the background'
        Details = @{}
        Warnings = @()
    }

    $procs = @(Get-Process -Name 'inspera-launcher' -ErrorAction SilentlyContinue)
    if ($procs.Count -gt 0) {
        $result.Passed = $false
        $result.Details.ProcessIds = @($procs | ForEach-Object { $_.Id })
        $result.Message = 'Inspera is already running in the background'
        $result.Warnings += 'Inspera is already running in the background  - open Task Manager, end inspera-launcher.exe, then start Inspera again (or restart the PC)'
    }

    return $result
}
