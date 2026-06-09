function Test-InsperaNetwork {
    param(
        [string]$InsperaUrl = 'https://www.inspera.com',
        [int]$TimeoutSec = 10
    )

    $result = @{
        Name = 'Network connectivity'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $InsperaUrl -Method Head -TimeoutSec $TimeoutSec -UseBasicParsing
        $sw.Stop()
        $result.Details.StatusCode = $response.StatusCode
        $result.Details.LatencyMs = $sw.ElapsedMilliseconds
        $result.Details.Url = $InsperaUrl

        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            $result.Passed = $true
            $result.Message = "Reachable ($($sw.ElapsedMilliseconds) ms)  - $InsperaUrl"
        } else {
            $result.Message = "Unexpected status $($response.StatusCode) from $InsperaUrl"
        }
    } catch {
        $result.Message = "Cannot reach $InsperaUrl  - $($_.Exception.Message)"
    }

    return $result
}
