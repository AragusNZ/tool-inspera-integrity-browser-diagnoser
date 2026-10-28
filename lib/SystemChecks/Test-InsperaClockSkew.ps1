function Test-InsperaClockSkew {
    param(
        [int]$MaxSkewSeconds = 30,
        [string]$NtpServer = 'time.google.com'
    )

    $result = @{
        Name = 'Clock accuracy'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $ntp = New-Object System.Net.Sockets.UdpClient
        $ntp.Connect($NtpServer, 123)

        $ntpData = New-Object byte[] 48
        $ntpData[0] = 0x1B
        [void]$ntp.Send($ntpData, $ntpData.Length)

        $receiveTask = $ntp.ReceiveAsync()
        $completed = $receiveTask.Wait(3000)
        $localUtc = [DateTime]::UtcNow

        if (-not $completed) {
            $result.Message = "NTP request to $NtpServer timed out (firewall may block UDP port 123)"
            $result.Details.LocalUtc = $localUtc.ToString('o')
            $ntp.Close()
            return $result
        }

        $response = $receiveTask.Result.Buffer
        $ntp.Close()

        $ntpUtc = Convert-InsperaNtpResponse -Response $response
        $skew = [Math]::Round([Math]::Abs(($localUtc - $ntpUtc).TotalSeconds), 2)
        $result.Details.LocalUtc = $localUtc.ToString('o')
        $result.Details.NtpUtc = $ntpUtc.ToString('o')
        $result.Details.SkewSeconds = $skew

        if ($skew -le $MaxSkewSeconds) {
            $result.Passed = $true
            $result.Message = "Clock skew ${skew}s (within ${MaxSkewSeconds}s limit)"
        } else {
            $result.Message = "Clock skew ${skew}s exceeds ${MaxSkewSeconds}s  - Settings > Time & language > Date & time > Sync now"
        }
    } catch {
        $result.Message = "Could not verify clock: $($_.Exception.Message)"
    }

    return $result
}
