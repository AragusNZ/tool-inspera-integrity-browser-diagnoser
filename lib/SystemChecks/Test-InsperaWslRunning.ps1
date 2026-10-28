function Test-InsperaWslRunning {
    $result = @{
        Name = 'WSL status'
        Passed = $true
        Message = 'WSL not detected or not running'
        Details = @{}
        OptionalFix = $null
    }

    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wsl) {
        return $result
    }

    try {
        # wsl.exe writes UTF-16; strip embedded nulls before matching
        $list = ((& wsl -l --running 2>&1) -join "`n") -replace "`0", ''
        $result.Details.Running = $list

        if ($LASTEXITCODE -eq 0 -and $list -notmatch 'no running distributions|no installed distributions') {
            $result.Passed = $false
            $result.Message = 'WSL distributions are running  - may trigger environment error'
            $result.OptionalFix = 'wsl --shutdown'
        }
    } catch {
        $result.Message = 'WSL check skipped'
    }

    return $result
}
