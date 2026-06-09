function New-InsperaSystemChecksSection {
    param(
        [string]$InsperaUrl,
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    $checks = Invoke-InsperaSystemChecks -InsperaUrl $InsperaUrl -Proctored:$Proctored -MaxDisplays $MaxDisplays
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

    $section = New-InsperaToolkitSection -Heading 'System readiness' -Level $(if ($failCount -gt 0) { 'fail' } else { 'pass' }) -Lines $checkLines
    return @{
        Section     = $section
        IssueCount  = $failCount
        FailCount   = $failCount
        Checks      = $checks
        PassedCount = $checks.Count - $failCount
        TotalCount  = $checks.Count
    }
}
