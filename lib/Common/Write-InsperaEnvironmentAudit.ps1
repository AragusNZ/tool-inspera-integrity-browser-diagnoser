function Write-InsperaEnvironmentAudit {
    param([array]$Results)

    $issues = 0
    foreach ($check in $Results) {
        if ($check.Name -eq 'Virtualization features') {
            if ($check.Warnings -and $check.Warnings.Count -gt 0) {
                foreach ($warning in $check.Warnings) {
                    Write-InsperaWarn $warning
                    $issues++
                }
            } else {
                Write-InsperaPass 'No virtualization warnings'
            }
            continue
        }

        $issues += Write-InsperaCheckResult -Check $check
    }
    return $issues
}
