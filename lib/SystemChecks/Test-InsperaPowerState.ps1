function Test-InsperaPowerState {
    $result = @{
        Name = 'Power state'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        if (-not $battery) {
            $result.Passed = $true
            $result.Message = 'No battery detected (desktop PC or always plugged in)'
            return $result
        }

        $status = $battery.BatteryStatus
        $result.Details.BatteryStatus = $status
        $result.Details.EstimatedCharge = $battery.EstimatedChargeRemaining

        # 2 = AC power, 6-9 = charging states
        if ($status -in 2, 6, 7, 8, 9) {
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
