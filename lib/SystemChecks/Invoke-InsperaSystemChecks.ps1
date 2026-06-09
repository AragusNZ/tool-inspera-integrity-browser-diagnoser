function Invoke-InsperaSystemChecks {
    param(
        [string]$InsperaUrl = 'https://www.inspera.com',
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    $checks = [System.Collections.Generic.List[object]]::new()

    $checks.Add((Test-InsperaClockSkew))
    $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
    $checks.Add((Test-InsperaPowerState))
    $checks.Add((Test-InsperaFreeMemory))
    $checks.Add((Test-InsperaSse42))
    $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
    $checks.Add((Test-InsperaTempWritable))
    $checks.Add((Test-InsperaRdpSession))
    $checks.Add((Test-InsperaWslRunning))
    $checks.Add((Test-InsperaVirtualizationFeatures))
    $checks.Add((Test-InsperaIibVersion))
    $checks.Add((Test-InsperaKeyboardLanguage))

    if ($Proctored) {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        $freeGb = if ($disk) { [Math]::Round($disk.FreeSpace / 1GB, 2) } else { 0 }
        $checks.Add([PSCustomObject]@{
            Name = 'Disk space (proctored)'
            Passed = ($freeGb -ge 0.5)
            Message = if ($freeGb -ge 0.5) { "${freeGb} GB free on C:" } else { "Only ${freeGb} GB free  - need 500 MB" }
            Details = @{ FreeGb = $freeGb }
        })
    }

    return @($checks)
}
