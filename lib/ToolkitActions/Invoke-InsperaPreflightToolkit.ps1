function Invoke-InsperaPreflightToolkit {
    param(
        [string]$LogPath,
        [string]$InsperaUrl,
        [switch]$Proctored,
        [int]$MaxDisplays = 1,
        [switch]$SkipEnvironmentAudit,
        [switch]$SkipSystemChecks,
        [switch]$SkipDiagnosis
    )

    $resolvedLogPath = if ($LogPath) { Get-InsperaLogPath -LogPath $LogPath } else { Get-InsperaLogPath }
    $effectiveUrl = Resolve-InsperaToolkitUrl -LogPath $resolvedLogPath -InsperaUrl $InsperaUrl
    $sections = [System.Collections.Generic.List[object]]::new()
    $issueCount = 0

    $liveMatches = Get-InsperaRunningBlocklistMatches -LogPath $resolvedLogPath

    if (-not $SkipDiagnosis) {
        $catalog = Get-InsperaErrorCatalog
        $parseResult = Parse-InsperaLog -LogPath $resolvedLogPath
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
    }

    if (-not $SkipEnvironmentAudit) {
        $envResult = New-InsperaEnvironmentSection
        $issueCount += $envResult.IssueCount
        $sections.Add($envResult.Section)
    }

    if (-not $SkipSystemChecks) {
        $checkResult = New-InsperaSystemChecksSection -InsperaUrl $effectiveUrl -Proctored:$Proctored -MaxDisplays $MaxDisplays
        $issueCount += $checkResult.IssueCount
        $sections.Add($checkResult.Section)
    }

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
