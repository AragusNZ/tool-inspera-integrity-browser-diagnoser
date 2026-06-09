function Get-InsperaDiagnosisSections {
    param(
        $ParseResult,
        $ErrorCatalog,
        $LiveBlocklistMatches,
        [string]$InsperaUrl,
        [string]$LogPath,
        [switch]$VerboseReport
    )

    $sections = [System.Collections.Generic.List[object]]::new()

    if (-not $ParseResult.Found) {
        $searchDirs = Get-InsperaLogSearchDirectories
        $sections.Add((New-InsperaToolkitSection -Heading 'No log found' -Level 'warn' -Lines @(
            'Inspera has not written a log file yet, or it is in a different folder.',
            'Try running Inspera once, then click this button again.',
            'Searched:',
            ($searchDirs | ForEach-Object { "  - $_" })
        )))
        return @($sections)
    }

    if ($ParseResult.Metadata -and $ParseResult.Metadata.Count -gt 0) {
        $metaLines = [System.Collections.Generic.List[string]]::new()
        if ($ParseResult.Metadata.Version) { $metaLines.Add("IIB version: $($ParseResult.Metadata.Version)") }
        if ($ParseResult.Metadata.SessionId) { $metaLines.Add("Session ID: $($ParseResult.Metadata.SessionId)") }
        if ($ParseResult.Metadata.Tenant) { $metaLines.Add("Tenant: $($ParseResult.Metadata.Tenant)") }
        if ($ParseResult.Metadata.LastSessionStatus) { $metaLines.Add("Last status: $($ParseResult.Metadata.LastSessionStatus)") }
        if ($metaLines.Count -gt 0) {
            $sections.Add((New-InsperaToolkitSection -Heading 'Last session' -Level 'info' -Lines $metaLines))
        }
    }

    if ($ParseResult.PrimaryFailure) {
        $key = $ParseResult.PrimaryFailure.Key
        $catalogEntry = $null
        if ($ErrorCatalog -and $ErrorCatalog.PSObject.Properties.Name -contains $key) {
            $catalogEntry = $ErrorCatalog.$key
        }

        $failLines = [System.Collections.Generic.List[string]]::new()
        if ($catalogEntry) {
            $failLines.Add($catalogEntry.title)
            $failLines.Add('')
            $failLines.Add('What this means:')
            $failLines.Add("  $($catalogEntry.userMessage)")
            $failLines.Add('')
            $failLines.Add('What to try:')
            $i = 1
            foreach ($fix in $catalogEntry.fixes) {
                $failLines.Add("  $i. $(Convert-InsperaFixToFriendly -Fix $fix)")
                $i++
            }
        } else {
            $failLines.Add($key)
            $failLines.Add("  $($ParseResult.PrimaryFailure.Message)")
        }

        $sections.Add((New-InsperaToolkitSection -Heading 'Why Inspera failed' -Level 'fail' -Lines $failLines))

        if ($ParseResult.FailureDetails -and $ParseResult.FailureDetails.Count -gt 0) {
            $sections.Add((New-InsperaToolkitSection -Heading 'Related details' -Level 'info' -Lines @($ParseResult.FailureDetails)))
        }

        $liveLines = [System.Collections.Generic.List[string]]::new()
        $targeted = Invoke-InsperaTargetedChecks -FailureKey $key -LogPath $LogPath -InsperaUrl $InsperaUrl
        if ($targeted.Count -gt 0) {
            foreach ($check in $targeted) {
                $liveLines.AddRange([string[]]@(Convert-InsperaCheckToLine -Check $check))
            }
            $worstLevel = 'pass'
            foreach ($check in $targeted) {
                $lvl = Convert-InsperaCheckToLevel -Check $check
                if ($lvl -eq 'fail') { $worstLevel = 'fail'; break }
                if ($lvl -eq 'warn' -and $worstLevel -ne 'fail') { $worstLevel = 'warn' }
            }
            $sections.Add((New-InsperaToolkitSection -Heading 'Live checks' -Level $worstLevel -Lines $liveLines))
        }

        if ($key -in @('Environment - failure', 'failed to close', 'Process blocklist - failure', 'iceworm failure', 'UI runtime error') -and $LiveBlocklistMatches.Count -gt 0) {
            $blockLines = @($LiveBlocklistMatches | ForEach-Object { "$($_.ProcessName) (still running)" })
            $blockLines += "Click 'Prepare my PC', then try Inspera again."
            $sections.Add((New-InsperaToolkitSection -Heading 'Apps still running' -Level 'warn' -Lines $blockLines))
        }
    } else {
        $sections.Add((New-InsperaToolkitSection -Heading 'No clear failure found' -Level 'warn' -Lines @(
            'The log does not match a known failure pattern.',
            'If Inspera still fails, ask exam support to review the log file.'
        )))
    }

    if ($ParseResult.Applications.Count -gt 0) {
        $sections.Add((New-InsperaToolkitSection -Heading 'Apps mentioned in log' -Level 'info' -Lines @($ParseResult.Applications | ForEach-Object { "- $_" })))
    }

    if ($VerboseReport -and $ParseResult.Timeline.Count -gt 0) {
        $timeline = @($ParseResult.Timeline | ForEach-Object { "Line $($_.LineNumber) [$($_.Key)]: $($_.Raw)" })
        $sections.Add((New-InsperaToolkitSection -Heading 'Full timeline' -Level 'info' -Lines $timeline))
    }

    return @($sections)
}
