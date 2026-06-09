function Invoke-InsperaWslShutdown {
    param([switch]$Apply)

    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wsl) {
        return @{ Ran = $false; Message = 'WSL not installed' }
    }

    if (-not $Apply) {
        return @{ Ran = $false; Message = 'Dry-run: would run wsl --shutdown' }
    }

    try {
        & wsl --shutdown 2>&1 | Out-Null
        return @{ Ran = $true; Message = 'WSL shutdown completed' }
    } catch {
        return @{ Ran = $false; Message = "WSL shutdown failed: $($_.Exception.Message)" }
    }
}
