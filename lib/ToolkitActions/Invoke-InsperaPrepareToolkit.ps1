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

    $envResult = New-InsperaEnvironmentSection -Apply:$Apply
    $issueCount += $envResult.IssueCount
    $sections.Add($envResult.Section)

    $checkResult = New-InsperaSystemChecksSection -InsperaUrl $effectiveUrl -Proctored:$Proctored -MaxDisplays $MaxDisplays
    $failCount = $checkResult.FailCount
    $issueCount += $checkResult.IssueCount
    $sections.Add($checkResult.Section)

    $sections.Add((New-InsperaToolkitSection -Heading 'Before you start Inspera' -Level 'info' -Lines @(Get-InsperaExamReminders -Context 'Prepare')))

    $modeLabel = if ($Apply) { 'Prepare complete' } else { 'Dry-run (no apps closed)' }
    $summary = "$modeLabel - $($checkResult.PassedCount)/$($checkResult.TotalCount) system checks passed"
    if (-not $Apply -and $blocklistHits.Count -gt 0) {
        $summary += '. Click Prepare my PC to close interfering apps.'
    }

    $status = if ($failCount -gt 0 -or $killFailed) { 'issues' } elseif ($issueCount -gt 0) { 'issues' } else { 'ok' }
    $exitCode = if ($failCount -gt 0) { 1 } else { 0 }

    return (New-InsperaToolkitResult -Status $status -Title 'Prepare my PC' -Summary $summary -Sections @($sections) -ExitCode $exitCode)
}
