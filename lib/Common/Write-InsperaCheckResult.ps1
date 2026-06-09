function Write-InsperaCheckResult {
    param($Check)

    if ($Check.Warnings -and $Check.Warnings.Count -gt 0) {
        foreach ($warning in $Check.Warnings) {
            Write-InsperaWarn $warning
        }
        return $(if ($Check.Warnings.Count -gt 0) { 1 } else { 0 })
    }

    if ($Check.Passed) {
        Write-InsperaPass "$($Check.Name): $($Check.Message)"
        return 0
    }

    Write-InsperaFail "$($Check.Name): $($Check.Message)"
    return 1
}
