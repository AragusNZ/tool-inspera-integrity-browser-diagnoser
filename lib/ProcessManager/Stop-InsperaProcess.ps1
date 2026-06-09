function Stop-InsperaProcess {
    param(
        [int]$ProcessId,
        [string]$ProcessName,
        [switch]$Apply
    )

    $result = [PSCustomObject]@{
        Id = $ProcessId
        ProcessName = $ProcessName
        Action = 'none'
        Success = $false
        Message = ''
    }

    if (-not $Apply) {
        $result.Action = 'would-kill'
        $result.Success = $true
        $result.Message = 'Dry-run: would terminate'
        return $result
    }

    try {
        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        $result.Action = 'stopped'
        $result.Success = $true
        $result.Message = 'Terminated gracefully'
        return $result
    } catch {
        # Fall through to taskkill
    }

    try {
        $null = & taskkill /F /T /PID $ProcessId 2>&1
        if ($LASTEXITCODE -eq 0) {
            $result.Action = 'taskkill'
            $result.Success = $true
            $result.Message = 'Terminated via taskkill /T'
        } else {
            $result.Action = 'failed'
            $result.Message = 'Could not terminate - try running as Administrator'
        }
    } catch {
        $result.Action = 'failed'
        $result.Message = $_.Exception.Message
    }

    return $result
}
