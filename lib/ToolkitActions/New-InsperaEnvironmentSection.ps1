function New-InsperaEnvironmentSection {
    param([switch]$Apply)

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

    $section = New-InsperaToolkitSection -Heading 'Environment' -Level $(if ($envIssues -gt 0) { 'warn' } else { 'pass' }) -Lines $envLines
    return @{ Section = $section; IssueCount = $envIssues }
}
