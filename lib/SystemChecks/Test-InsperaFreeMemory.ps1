function Test-InsperaFreeMemory {
    param([long]$MinFreeMb = 2048)

    $result = @{
        Name = 'Free memory'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $freeMb = [Math]::Round($os.FreePhysicalMemory / 1024, 0)
        $totalMb = [Math]::Round($os.TotalVisibleMemorySize / 1024, 0)
        $result.Details.FreeMb = $freeMb
        $result.Details.TotalMb = $totalMb

        if ($freeMb -ge $MinFreeMb) {
            $result.Passed = $true
            $result.Message = "${freeMb} MB free of ${totalMb} MB total"
        } else {
            $result.Message = "Only ${freeMb} MB free (need ${MinFreeMb} MB)  - close applications"
        }
    } catch {
        $result.Message = "Could not check memory: $($_.Exception.Message)"
    }

    return $result
}
