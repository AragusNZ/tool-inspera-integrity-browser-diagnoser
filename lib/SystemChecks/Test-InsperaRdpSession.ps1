function Test-InsperaRdpSession {
    $result = @{
        Name = 'Remote session'
        Passed = $true
        Message = 'No active remote desktop session detected'
        Details = @{}
    }

    try {
        $sessions = query session 2>$null
        if ($sessions -match 'rdp-tcp|Active\s+rdp') {
            $result.Passed = $false
            $result.Message = 'Remote desktop session active  - IIB may flag environment error'
        }
    } catch {
        $result.Message = 'Remote session check skipped'
    }

    return $result
}
