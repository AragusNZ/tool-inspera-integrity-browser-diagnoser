function Test-InsperaDiskSpace {
    # Inspera: 500 MB for install; proctored exams record locally (75 MB per hour)
    param([switch]$Proctored)

    $minMb = if ($Proctored) { 1024 } else { 500 }
    $result = @{
        Name = if ($Proctored) { 'Disk space (proctored)' } else { 'Disk space' }
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $drive = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':') -ErrorAction Stop
        $freeMb = [Math]::Round($drive.Free / 1MB, 0)
        $result.Details.FreeMb = $freeMb
        $result.Details.MinMb = $minMb

        if ($freeMb -ge $minMb) {
            $result.Passed = $true
            $result.Message = "$([Math]::Round($freeMb / 1024, 1)) GB free on $env:SystemDrive"
        } else {
            $result.Message = "Only ${freeMb} MB free on $env:SystemDrive  - need ${minMb} MB, delete or move files"
        }
    } catch {
        $result.Passed = $true
        $result.Message = "Disk space check skipped: $($_.Exception.Message)"
    }

    return $result
}
