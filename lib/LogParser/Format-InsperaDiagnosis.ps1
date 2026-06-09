function Format-InsperaDiagnosis {
    param(
        [hashtable]$ParseResult,
        [object]$ErrorCatalog,
        [array]$LiveBlocklistMatches = @()
    )

    $lines = [System.Collections.Generic.List[string]]::new()

    if (-not $ParseResult.Found) {
        $searchDirs = Get-InsperaLogSearchDirectories
        $lines.Add('No inspera-launcher-*.log found in configured log directories.')
        $lines.Add('Run IIB once (even if it fails), then run diagnose.ps1 again.')
        $lines.Add('Searched:')
        foreach ($dir in $searchDirs) {
            $lines.Add("  - $dir")
        }
        $lines.Add("Config: $(Get-InsperaConfigPath)")
        return $lines
    }

    $lines.Add("Log: $($ParseResult.LogPath)")
    $lines.Add("Modified: $($ParseResult.LastWriteTime)")
    $lines.Add("Lines: $($ParseResult.LineCount)")

    if ($ParseResult.Metadata -and $ParseResult.Metadata.Count -gt 0) {
        $lines.Add('')
        $lines.Add('SESSION INFO (from log):')
        if ($ParseResult.Metadata.Version) { $lines.Add("  IIB version: $($ParseResult.Metadata.Version)") }
        if ($ParseResult.Metadata.SessionId) { $lines.Add("  Session ID: $($ParseResult.Metadata.SessionId)") }
        if ($ParseResult.Metadata.Tenant) { $lines.Add("  Tenant: $($ParseResult.Metadata.Tenant)") }
        if ($ParseResult.Metadata.Platform) { $lines.Add("  Platform: $($ParseResult.Metadata.Platform)") }
        if ($ParseResult.Metadata.Machine) { $lines.Add("  Machine: $($ParseResult.Metadata.Machine)") }
        if ($ParseResult.Metadata.ClockOffsetSeconds -ne $null) {
            $lines.Add("  Clock offset: $($ParseResult.Metadata.ClockOffsetSeconds)s")
        }
        if ($ParseResult.Metadata.Displays) { $lines.Add("  Displays: $($ParseResult.Metadata.Displays)") }
        if ($ParseResult.Metadata.KeyboardLayouts) { $lines.Add("  Keyboard: $($ParseResult.Metadata.KeyboardLayouts)") }
        if ($ParseResult.Metadata.LastSessionStatus) { $lines.Add("  Last status: $($ParseResult.Metadata.LastSessionStatus)") }
    }

    $lines.Add('')

    if ($ParseResult.PrimaryFailure) {
        $key = $ParseResult.PrimaryFailure.Key
        $catalogEntry = $null
        if ($ErrorCatalog -and $ErrorCatalog.PSObject.Properties.Name -contains $key) {
            $catalogEntry = $ErrorCatalog.$key
        }

        $lines.Add("PRIMARY FAILURE: $key")
        if ($catalogEntry) {
            $lines.Add("  Title: $($catalogEntry.title)")
            $lines.Add("  Meaning: $($catalogEntry.userMessage)")
            $lines.Add('  Likely causes:')
            foreach ($cause in $catalogEntry.causes) {
                $lines.Add("    - $cause")
            }
            $lines.Add('  Recommended fixes:')
            foreach ($fix in $catalogEntry.fixes) {
                $lines.Add("    - $fix")
            }
        } else {
            $lines.Add("  Message: $($ParseResult.PrimaryFailure.Message)")
            $lines.Add('  (No catalog entry - run with -VerboseReport for full log context)')
        }

        $lines.Add('')
        $lines.Add("  Log line $($ParseResult.PrimaryFailure.LineNumber): $($ParseResult.PrimaryFailure.Raw)")

        if ($ParseResult.FailureDetails -and $ParseResult.FailureDetails.Count -gt 0) {
            $lines.Add('  Related log context:')
            foreach ($detail in $ParseResult.FailureDetails) {
                $lines.Add("    - $detail")
            }
        }
    } else {
        $lines.Add('No explicit failure pattern found in log.')
        $lines.Add('The log may use an unrecognized format. Run with -VerboseReport or copy the log for calibration.')
    }

    if ($ParseResult.SystemChecks -and $ParseResult.SystemChecks.Count -gt 0) {
        $lines.Add('')
        $lines.Add('SYSTEM CHECK TIMELINE:')
        foreach ($event in $ParseResult.SystemChecks) {
            $symbol = switch ($event.Type) {
                'pass' { 'PASS' }
                'fail' { 'FAIL' }
                default { '....' }
            }
            $lines.Add("  [$symbol] $($event.Check) (line $($event.LineNumber))")
        }
    }

    if ($ParseResult.Applications.Count -gt 0) {
        $lines.Add('')
        $lines.Add('APPLICATIONS MENTIONED IN LOG:')
        foreach ($app in $ParseResult.Applications) {
            $lines.Add("  - $app")
        }
    }

    if ($LiveBlocklistMatches.Count -gt 0) {
        $lines.Add('')
        $lines.Add('CURRENTLY RUNNING BLOCKLIST MATCHES:')
        foreach ($proc in $LiveBlocklistMatches) {
            $lines.Add("  - $($proc.ProcessName) (PID $($proc.Id)) [$($proc.Category)]")
        }
    }

    if ($ParseResult.Failures.Count -gt 1 -and $ParseResult.PrimaryFailure) {
        $others = @($ParseResult.Failures | Where-Object {
            $_.LineNumber -ne $ParseResult.PrimaryFailure.LineNumber
        })
        if ($others.Count -gt 0) {
            $lines.Add('')
            $lines.Add("OTHER FAILURES IN LOG ($($others.Count)):")
            foreach ($f in $others) {
                $lines.Add("  - Line $($f.LineNumber): $($f.Key) - $($f.Message)")
            }
        }
    }

    return $lines
}
