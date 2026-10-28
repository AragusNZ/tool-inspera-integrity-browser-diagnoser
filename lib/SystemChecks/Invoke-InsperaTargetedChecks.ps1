function Invoke-InsperaTargetedChecks {
    param(
        [string]$FailureKey,
        [string]$LogPath,
        [string]$InsperaUrl = 'https://www.inspera.com',
        [int]$MaxDisplays = 1
    )

    if (-not $FailureKey) {
        return @()
    }

    $checks = [System.Collections.Generic.List[object]]::new()

    # The cloudfront connectionCheck.json URL IIB actually probes, when the log recorded it
    $connectionCheckUrl = $null
    if ($LogPath -and (Test-Path $LogPath)) {
        $connectionCheckUrl = (Get-InsperaLogMetadata -Lines @(Get-Content -Path $LogPath -ErrorAction SilentlyContinue)).ConnectionCheckUrl
    }

    switch ($FailureKey) {
        'Environment - failure' {
            foreach ($item in (Get-InsperaEnvironmentAuditResults)) {
                $checks.Add($item)
            }
        }
        'failed to close' {
            # Blocklist scan handled separately in diagnose via live matches
        }
        'Process blocklist - failure' {
            # Blocklist scan shown separately via LiveBlocklistMatches in diagnosis sections
        }
        'Connection quality - failure' {
            $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
            if ($connectionCheckUrl) { $checks.Add((Test-InsperaNetwork -InsperaUrl $connectionCheckUrl)) }
            $checks.Add((Test-InsperaConnectionQuality -InsperaUrl $InsperaUrl))
        }
        'Clock accuracy - failure' {
            $checks.Add((Test-InsperaClockSkew))
        }
        'Number of screens - failure' {
            $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
        }
        'Power state - failure' {
            $checks.Add((Test-InsperaPowerState))
        }
        'Memory Check - failure' {
            $checks.Add((Test-InsperaFreeMemory))
        }
        'CPU features - failure' {
            $checks.Add((Test-InsperaSse42))
        }
        'App version - failure' {
            $checks.Add((Test-InsperaIibVersion))
        }
        'Incorrect keyboard language' {
            $checks.Add((Test-InsperaKeyboardLanguage))
        }
        'After completion - failed' {
            $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
        }
        'Screen Capture' {
            $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
        }
        'Failed to capture screen' {
            $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
        }
        'Cannot upload files' {
            $checks.Add((Test-InsperaConnectionQuality -InsperaUrl $InsperaUrl))
        }
        'desktop changed' {
            $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
        }
        'iceworm failure' {
            $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
            if ($connectionCheckUrl) { $checks.Add((Test-InsperaNetwork -InsperaUrl $connectionCheckUrl)) }
            $checks.Add((Test-InsperaConnectionQuality -InsperaUrl $InsperaUrl))
            $checks.Add((Test-InsperaGraphicsDriver))
        }
        'system check aborted' {
            $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
        }
        'UI runtime error' {
            $checks.Add((Test-InsperaGraphicsDriver))
            $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
        }
        'Webcam' {
            $checks.Add((Test-InsperaWebcam))
        }
        'Configuration download failed' {
            $checks.Add((Test-InsperaAdminRights))
            $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
        }
        'IIB already running' {
            $checks.Add((Test-InsperaIibRunning))
        }
        default { }
    }

    return @($checks)
}
