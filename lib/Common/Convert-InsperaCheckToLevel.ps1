function Convert-InsperaCheckToLevel {
    param($Check)

    if ($Check.Warnings -and $Check.Warnings.Count -gt 0) {
        return 'warn'
    }
    if ($Check.Passed) {
        return 'pass'
    }
    return 'fail'
}
