function Test-InsperaPowerState {
    $result = @{
        Name = 'Power state'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $power = [System.Windows.Forms.SystemInformation]::PowerStatus
        $result.Details.PowerLineStatus = [string]$power.PowerLineStatus
        $result.Details.BatteryChargeStatus = [string]$power.BatteryChargeStatus

        if ($power.BatteryChargeStatus -eq 'NoSystemBattery') {
            $result.Passed = $true
            $result.Message = 'No battery detected (desktop PC or always plugged in)'
        } elseif ($power.PowerLineStatus -eq 'Online') {
            $result.Passed = $true
            $result.Message = 'On AC power / charging'
        } else {
            $result.Message = 'Running on battery  - plug in charger before exam'
        }
    } catch {
        $result.Passed = $true
        $result.Message = "Power state check skipped: $($_.Exception.Message)"
    }

    return $result
}
