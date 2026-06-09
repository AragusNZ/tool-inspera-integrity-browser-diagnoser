function Get-InsperaLogSearchDirectories {
    $config = Get-InsperaConfig
    $dirs = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $config.logDirectories) {
        $resolved = Resolve-InsperaConfigPath -Path $entry
        if ($resolved -and (Test-Path $resolved) -and ($dirs -notcontains $resolved)) {
            [void]$dirs.Add($resolved)
        } elseif ($resolved -and ($dirs -notcontains $resolved)) {
            # Include configured path even if missing - helps error messages
            [void]$dirs.Add($resolved)
        }
    }

    if ($config.fallbackToUserTemp) {
        $userTemp = [System.IO.Path]::GetTempPath().TrimEnd('\')
        if ($dirs -notcontains $userTemp) {
            [void]$dirs.Add($userTemp)
        }
    }

    if ($dirs.Count -eq 0) {
        [void]$dirs.Add([System.IO.Path]::GetTempPath().TrimEnd('\'))
    }

    return @($dirs)
}
