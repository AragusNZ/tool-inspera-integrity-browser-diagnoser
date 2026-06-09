function Invoke-InsperaPrepareToolkit {
    param(
        [switch]$Apply,
        [string]$LogPath,
        [string]$InsperaUrl,
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    $resolvedLogPath = if ($LogPath) { Get-InsperaLogPath -LogPath $LogPath } else { Get-InsperaLogPath }
    $effectiveUrl = Resolve-InsperaToolkitUrl -LogPath $resolvedLogPath -InsperaUrl $InsperaUrl
    $sections = [System.Collections.Generic.List[object]]::new()
    $issueCount = 0
    $killFailed = $false

    # Phase 1: Blocklisted processes
    $blocklistHits = Get-InsperaRunningBlocklistMatches -LogPath $resolvedLogPath
    $phase1Lines = [System.Collections.Generic.List[string]]::new()

    if ($blocklistHits.Count -eq 0) {
        $phase1Lines.Add('[PASS] No interfering apps running')
    } else {
        if (-not $Apply) {
            $phase1Lines.Add("[INFO] $($blocklistHits.Count) app(s) would be closed (dry-run)")
            foreach ($hit in $blocklistHits) {
                $phase1Lines.Add("  - $($hit.ProcessName)")
            }
            $phase1Lines.Add("Run with -Apply or use 'Prepare my PC' in the toolkit to close them.")
            $issueCount += $blocklistHits.Count
        } else {
            foreach ($hit in $blocklistHits) {
                $phase1Lines.Add("  - $($hit.ProcessName) (found)")
            }
            $cleanup = Invoke-InsperaProcessCleanup -LogPath $resolvedLogPath -Apply:$Apply
            foreach ($r in $cleanup) {
                if ($r.Success) {
                    $phase1Lines.Add("[PASS] $($r.ProcessName): closed")
                } else {
                    $phase1Lines.Add("[FAIL] $($r.ProcessName): $($r.Message)")
                    $killFailed = $true
                    $issueCount++
                }
            }
            if ($killFailed) {
                $phase1Lines.Add('Some apps need Administrator - ask exam support to run the toolkit as admin.')
            }
        }
    }

    $phase1Level = if ($killFailed) { 'fail' } elseif ($blocklistHits.Count -gt 0 -and -not $Apply) { 'warn' } else { 'pass' }
    $sections.Add((New-InsperaToolkitSection -Heading 'Interfering apps' -Level $phase1Level -Lines $phase1Lines))

    # Phase 2: Environment audit
    $envResults = Get-InsperaEnvironmentAuditResults
    $envLines = [System.Collections.Generic.List[string]]::new()
    $envIssues = 0
    foreach ($check in $envResults) {
        if ($check.Name -eq 'Virtualization features') {
            if ($check.Warnings -and $check.Warnings.Count -gt 0) {
                foreach ($warning in $check.Warnings) {
                    $envLines.Add("[WARN] $warning")
                    $envIssues++
                }
            } else {
                $envLines.Add('[PASS] No virtualization warnings')
            }
            continue
        }
        $envLines.AddRange([string[]]@(Convert-InsperaCheckToLine -Check $check))
        if (-not $check.Passed) { $envIssues++ }
    }

    $wsl = $envResults | Where-Object { $_.Name -eq 'WSL status' } | Select-Object -First 1
    if ($wsl -and -not $wsl.Passed -and $wsl.OptionalFix -and $Apply) {
        $wslResult = Invoke-InsperaWslShutdown -Apply:$Apply
        $envLines.Add("[INFO] $($wslResult.Message)")
    } elseif ($wsl -and -not $wsl.Passed -and -not $Apply) {
        $envLines.Add('[INFO] WSL is running - will be shut down when you prepare with Apply')
    }

    $issueCount += $envIssues
    $envLevel = if ($envIssues -gt 0) { 'warn' } else { 'pass' }
    $sections.Add((New-InsperaToolkitSection -Heading 'Environment' -Level $envLevel -Lines $envLines))

    # Phase 3: System checks
    $checks = Invoke-InsperaSystemChecks -InsperaUrl $effectiveUrl -Proctored:$Proctored -MaxDisplays $MaxDisplays
    $checkLines = [System.Collections.Generic.List[string]]::new()
    $failCount = 0
    foreach ($check in $checks) {
        $checkLines.AddRange([string[]]@(Convert-InsperaCheckToLine -Check $check))
        if ($check.Name -ne 'Keyboard language' -and -not $check.Passed) {
            if (-not ($check.Warnings -and $check.Warnings.Count -gt 0)) {
                $failCount++
            }
        }
    }
    $issueCount += $failCount
    $checkLevel = if ($failCount -gt 0) { 'fail' } else { 'pass' }
    $sections.Add((New-InsperaToolkitSection -Heading 'System readiness' -Level $checkLevel -Lines $checkLines))

    # Phase 4: Reminders
    $reminders = @(
        'Use a single monitor during Inspera system checks',
        'Close virtual desktops (Win+Tab) before starting',
        'Disable VPN unless your institution requires it',
        'Plug in charger if prompted by Inspera',
        'Close Chrome extensions (especially Avast) before exam'
    )
    $sections.Add((New-InsperaToolkitSection -Heading 'Before you start Inspera' -Level 'info' -Lines $reminders))

    $passedChecks = $checks.Count - $failCount
    $modeLabel = if ($Apply) { 'Prepare complete' } else { 'Dry-run (no apps closed)' }
    $summary = "$modeLabel - $passedChecks/$($checks.Count) system checks passed"
    if (-not $Apply -and $blocklistHits.Count -gt 0) {
        $summary += '. Click Prepare my PC to close interfering apps.'
    }

    $status = if ($failCount -gt 0 -or $killFailed) { 'issues' } elseif ($issueCount -gt 0) { 'issues' } else { 'ok' }
    $exitCode = if ($failCount -gt 0) { 1 } else { 0 }

    return (New-InsperaToolkitResult -Status $status -Title 'Prepare my PC' -Summary $summary -Sections @($sections) -ExitCode $exitCode)
}
