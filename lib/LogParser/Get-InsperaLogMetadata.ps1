function Get-InsperaLogMetadata {
    param([string[]]$Lines)

    $meta = @{}

    foreach ($line in $Lines) {
        $msg = (Parse-InsperaLogLine -Line $line).Message

        if ($msg -match '^launching Inspera Integrity Browser v([\d.]+)') { $meta.Version = $Matches[1] }
        if ($msg -match '^session ID (\d+)') { $meta.SessionId = $Matches[1] }
        if ($msg -match '^tenant domain (.+)') { $meta.Tenant = $Matches[1] }
        if ($msg -match '^host platform: (.+)') { $meta.Platform = $Matches[1] }
        if ($msg -match '^machine name (.+?), vendor') { $meta.Machine = $Matches[1].Trim() }
        if ($msg -match '^CPU model (.+?), vendor') { $meta.Cpu = $Matches[1].Trim() }
        if ($msg -match '^keyboard layouts \[(.+)\]') { $meta.KeyboardLayouts = $Matches[1] }
        if ($msg -match '^active displays \[(.+)\]') { $meta.Displays = $Matches[1] }
        if ($msg -match '^clock offset to NTP server ([-\d.]+)s') {
            $meta.ClockOffsetSeconds = [Math]::Round([double]$Matches[1], 2)
        }
        if ($msg -match '^session status (.+)') { $meta.LastSessionStatus = $Matches[1] }
        if ($msg -match 'requested frame URL (.+connectionCheck\.json)') { $meta.ConnectionCheckUrl = $Matches[1] }
    }

    return $meta
}
