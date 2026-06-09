function Test-InsperaConnectionQuality {
    param(
        [string]$InsperaUrl = 'https://www.inspera.com',
        [int]$Samples = 3,
        [int]$MaxLatencyMs = 2000
    )

    $result = @{
        Name = 'Connection quality'
        Passed = $false
        Message = ''
        Details = @{}
    }

    $latencies = [System.Collections.Generic.List[int]]::new()
    $failures = 0

    for ($i = 0; $i -lt $Samples; $i++) {
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $InsperaUrl -Method Head -TimeoutSec 10 -UseBasicParsing
            $sw.Stop()
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                $latencies.Add([int]$sw.ElapsedMilliseconds)
            } else {
                $failures++
            }
        } catch {
            $failures++
        }
    }

    if ($latencies.Count -eq 0) {
        $result.Message = "Could not reach $InsperaUrl ($failures/$Samples attempts failed)"
        return $result
    }

    $avg = [int]($latencies | Measure-Object -Average).Average
    $max = ($latencies | Measure-Object -Maximum).Maximum
    $result.Details.AverageLatencyMs = $avg
    $result.Details.MaxLatencyMs = $max
    $result.Details.Samples = $latencies.Count
    $result.Details.Url = $InsperaUrl

    if ($avg -le $MaxLatencyMs) {
        $result.Passed = $true
        $result.Message = "Avg latency ${avg}ms, max ${max}ms ($($latencies.Count)/$Samples OK)"
    } else {
        $result.Message = "High latency (avg ${avg}ms)  - try ethernet or a different network"
    }

    return $result
}
