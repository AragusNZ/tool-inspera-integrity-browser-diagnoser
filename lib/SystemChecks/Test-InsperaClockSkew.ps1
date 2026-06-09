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
        $localUtc = (Get-Date).ToUniversalTime()

        $ntp = New-Object System.Net.Sockets.UdpClient
        $ntp.Connect($NtpServer, 123)

        $ntpData = New-Object byte[] 48
        $ntpData[0] = 0x1B
        [void]$ntp.Send($ntpData, $ntpData.Length)

        $receiveTask = $ntp.ReceiveAsync()
        $completed = $receiveTask.Wait(3000)

        if (-not $completed) {
            $result.Message = "NTP request to $NtpServer timed out (firewall may block port 123)"
            $result.Details.LocalUtc = $localUtc.ToString('o')
            $ntp.Close()
            return $result
        }

        $response = $receiveTask.Result.Buffer
        $ntp.Close()

        $intPart = [BitConverter]::ToUInt32($response[40..43], 0)
        $fractPart = [BitConverter]::ToUInt32($response[44..47], 0)
        $ntpSeconds = $intPart + ($fractPart / 4294967296.0)
        $ntpEpoch = Get-Date '1970-01-01 00:00:00Z'
        $ntpUtc = $ntpEpoch.AddSeconds($ntpSeconds - 2208988800)

        $skew = [Math]::Abs(($localUtc - $ntpUtc).TotalSeconds)
        $result.Details.LocalUtc = $localUtc.ToString('o')
        $result.Details.NtpUtc = $ntpUtc.ToString('o')
        $result.Details.SkewSeconds = [Math]::Round($skew, 2)

        if ($skew -le $MaxSkewSeconds) {
            $result.Passed = $true
            $result.Message = "Clock skew ${skew}s (within ${MaxSkewSeconds}s limit)"
        } else {
            $result.Message = "Clock skew ${skew}s exceeds ${MaxSkewSeconds}s  - enable automatic time sync"
        }
    } catch {
        $result.Message = "Could not verify clock: $($_.Exception.Message)"
    }

    return $result
}
