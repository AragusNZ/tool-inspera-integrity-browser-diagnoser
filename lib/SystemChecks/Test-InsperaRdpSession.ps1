function Test-InsperaRdpSession {
    $result = @{
        Name = 'Remote session'
        Passed = $true
        Message = 'Not a remote desktop session'
        Details = @{}
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $remote = [System.Windows.Forms.SystemInformation]::TerminalServerSession
        $result.Details.SessionName = $env:SESSIONNAME
        if ($remote) {
            $result.Passed = $false
            $result.Message = 'Remote desktop session active  - Inspera cannot run within a remote session, use the PC directly'
        }
    } catch {
        $result.Message = 'Remote session check skipped'
    }

    return $result
}
