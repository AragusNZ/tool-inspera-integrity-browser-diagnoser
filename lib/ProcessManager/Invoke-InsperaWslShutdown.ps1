function Invoke-InsperaWslShutdown {
    param([switch]$Apply)

    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wsl) {
        return @{ Ran = $false; Message = 'WSL not installed' }
    }

    if (-not $Apply) {
        return @{ Ran = $false; Message = 'Dry-run: would run wsl --shutdown' }
    }

    if ($env:INSPERA_TEST_MODE -eq '1' -or $env:INSPERA_SKIP_WSL_SHUTDOWN -eq '1') {
        return @{ Ran = $false; Message = 'Skipped WSL shutdown (test mode)' }
    }

    try {
        & wsl --shutdown 2>&1 | Out-Null
        return @{ Ran = $true; Message = 'WSL shutdown completed' }
    } catch {
        return @{ Ran = $false; Message = "WSL shutdown failed: $($_.Exception.Message)" }
    }
}
