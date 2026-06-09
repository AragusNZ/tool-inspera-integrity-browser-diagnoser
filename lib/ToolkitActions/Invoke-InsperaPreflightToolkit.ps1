function Invoke-InsperaPreflightToolkit {
    param(
        [string]$LogPath,
        [string]$InsperaUrl,
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    $resolvedLogPath = if ($LogPath) { Get-InsperaLogPath -LogPath $LogPath } else { Get-InsperaLogPath }
    $effectiveUrl = Resolve-InsperaToolkitUrl -LogPath $resolvedLogPath -InsperaUrl $InsperaUrl
    $sections = [System.Collections.Generic.List[object]]::new()
    $issueCount = 0

    $catalog = Get-InsperaErrorCatalog
    $parseResult = Parse-InsperaLog -LogPath $resolvedLogPath
    $liveMatches = Get-InsperaRunningBlocklistMatches -LogPath $resolvedLogPath
    $diagSections = Get-InsperaDiagnosisSections -ParseResult $parseResult -ErrorCatalog $catalog `
        -LiveBlocklistMatches $liveMatches -InsperaUrl $effectiveUrl -LogPath $resolvedLogPath

    if ($parseResult.PrimaryFailure) {
        $issueCount++
    }
    foreach ($ds in $diagSections) {
        if ($ds.Heading -eq 'Why Inspera failed' -or $ds.Heading -eq 'No log found' -or $ds.Heading -eq 'No clear failure found') {
            $sections.Add($ds)
        }
    }

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
    $issueCount += $envIssues
    $sections.Add((New-InsperaToolkitSection -Heading 'Environment' -Level $(if ($envIssues -gt 0) { 'warn' } else { 'pass' }) -Lines $envLines))

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
    $sections.Add((New-InsperaToolkitSection -Heading 'System readiness' -Level $(if ($failCount -gt 0) { 'fail' } else { 'pass' }) -Lines $checkLines))

    $blockLines = [System.Collections.Generic.List[string]]::new()
    if ($liveMatches.Count -eq 0) {
        $blockLines.Add('[PASS] No interfering apps running')
    } else {
        foreach ($hit in $liveMatches) {
            $blockLines.Add("[WARN] $($hit.ProcessName) (still running)")
        }
        $blockLines.Add("Click 'Prepare my PC' to close these before your exam.")
        $issueCount += $liveMatches.Count
    }
    $sections.Add((New-InsperaToolkitSection -Heading 'Interfering apps' -Level $(if ($liveMatches.Count -gt 0) { 'warn' } else { 'pass' }) -Lines $blockLines))

    $summary = if ($issueCount -eq 0) {
        'Your PC looks ready for Inspera.'
    } else {
        "$issueCount issue(s) found - see details below."
    }

    $status = if ($issueCount -eq 0) { 'ok' } else { 'issues' }
    return (New-InsperaToolkitResult -Status $status -Title 'Am I ready?' -Summary $summary -Sections @($sections) -ExitCode $(if ($issueCount -gt 0) { 1 } else { 0 }))
}
