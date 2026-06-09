function Test-InsperaDisplayCount {
    param([int]$MaxDisplays = 1)

    $result = @{
        Name = 'Display count'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $count = $screens.Count
        $result.Details.Count = $count
        $result.Details.Monitors = @($screens | ForEach-Object { $_.DeviceName })

        if ($count -le $MaxDisplays) {
            $result.Passed = $true
            $result.Message = "$count display(s) detected"
        } else {
            $result.Message = "$count displays detected  - disconnect secondary monitor for IIB checks"
        }
    } catch {
        $result.Message = "Could not enumerate displays: $($_.Exception.Message)"
    }

    return $result
}
